# Security Controls Implementation Guide — 143it Azure DevOps

> **Related:** [Security Baseline](security_baseline.md) | [Disaster Recovery](disaster_recovery_plan.md) | [Monitoring Plan](monitoring_plan.md)

This document provides detailed implementation procedures for security controls. The [Security Baseline](security_baseline.md) defines *what* security measures are required; this guide explains *how* to implement them.

---

## 1. Data Encryption Standards

### 1.1 Encryption at Rest

| Component | Encryption Method | Key Management |
|-----------|-------------------|----------------|
| Azure Repos | Azure Storage Service Encryption (SSE) | Microsoft-managed keys (default) |
| Azure Artifacts | Azure Storage SSE | Microsoft-managed keys |
| Azure Boards (Work Items) | Azure SQL TDE | Microsoft-managed keys |
| Backup Storage | Azure Storage SSE + customer key | Azure Key Vault (CMK) |
| Database (App Data) | Azure SQL TDE | Customer-managed key in Key Vault |

**Implementation:**

```bash
# Enable customer-managed keys for Azure SQL
az sql db tde set \
  --resource-group $RG \
  --server $SQL_SERVER \
  --database $DB_NAME \
  --status Enabled

# Configure Key Vault for TDE
az sql server tde-key set \
  --resource-group $RG \
  --server $SQL_SERVER \
  --server-key-type AzureKeyVault \
  --kid "https://$KEYVAULT.vault.azure.net/keys/$KEY_NAME/$KEY_VERSION"
```

### 1.2 Encryption in Transit

| Connection | Protocol | Minimum Version |
|------------|----------|-----------------|
| Azure DevOps API | HTTPS | TLS 1.2 |
| Azure Portal | HTTPS | TLS 1.2 |
| Git operations | HTTPS or SSH | TLS 1.2 / SSH-2 |
| Database connections | TLS | TLS 1.2 |
| Internal service communication | mTLS | TLS 1.2 |

**Enforcement:**

- [ ] Disable TLS 1.0/1.1 at Azure Front Door / Application Gateway
- [ ] Configure minimum TLS version on Azure SQL: `az sql server update --minimal-tls-version 1.2`
- [ ] Enforce HTTPS-only on App Services: `az webapp update --https-only true`

### 1.3 Key Management

| Key Type | Rotation Period | Storage |
|----------|-----------------|---------|
| TDE keys | Annual | Azure Key Vault (HSM-backed) |
| API keys | 90 days | Azure Key Vault |
| Service Principal secrets | 90 days | Azure Key Vault |
| SSL/TLS certificates | Annual (auto-renew) | Azure Key Vault |
| PATs | 90 days max | Azure DevOps (user-managed) |

**Key Vault Configuration:**

```bash
# Create Key Vault with HSM protection
az keyvault create \
  --name $KV_NAME \
  --resource-group $RG \
  --location $LOCATION \
  --sku premium \
  --enable-purge-protection true \
  --enable-soft-delete true \
  --retention-days 90

# Enable diagnostic logging
az monitor diagnostic-settings create \
  --resource $KV_RESOURCE_ID \
  --name "kv-audit-logs" \
  --logs '[{"category":"AuditEvent","enabled":true,"retentionPolicy":{"enabled":true,"days":365}}]' \
  --workspace $LOG_ANALYTICS_WORKSPACE_ID
```

---

## 2. Vulnerability Management

### 2.1 Static Application Security Testing (SAST)

**Tooling:** SonarQube / SonarCloud

**Pipeline Integration:**

```yaml
# azure-pipelines.yml - SAST stage
- stage: SAST
  jobs:
  - job: SonarScan
    steps:
    - task: SonarQubePrepare@5
      inputs:
        SonarQube: 'SonarQube-ServiceConnection'
        scannerMode: 'MSBuild'
        projectKey: '$(Build.Repository.Name)'
        projectName: '$(Build.Repository.Name)'
        extraProperties: |
          sonar.coverage.exclusions=**/tests/**
          sonar.cs.opencover.reportsPaths=$(Agent.TempDirectory)/**/coverage.opencover.xml

    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'

    - task: SonarQubeAnalyze@5

    - task: SonarQubePublish@5
      inputs:
        pollingTimeoutSec: '300'
```

**Quality Gate Criteria (Blocking):**

| Metric | Threshold | Action |
|--------|-----------|--------|
| Critical vulnerabilities | 0 | Block PR merge |
| High vulnerabilities | 0 | Block PR merge |
| Medium vulnerabilities | ≤ 5 (new code) | Warning |
| Code coverage | ≥ 80% | Block PR merge |
| Duplicated lines | < 3% | Warning |

### 2.2 Dynamic Application Security Testing (DAST)

**Tooling:** OWASP ZAP

**Pipeline Integration:**

```yaml
# DAST stage - runs against staging environment
- stage: DAST
  dependsOn: DeployStaging
  jobs:
  - job: ZAPScan
    steps:
    - task: Bash@3
      displayName: 'Run OWASP ZAP Scan'
      inputs:
        targetType: 'inline'
        script: |
          docker run --rm \
            -v $(System.DefaultWorkingDirectory)/reports:/zap/wrk:rw \
            owasp/zap2docker-stable zap-full-scan.py \
            -t https://$(STAGING_URL) \
            -r zap-report.html \
            -x zap-report.xml \
            -c zap-rules.conf

    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'NUnit'
        testResultsFiles: '**/zap-report.xml'

    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(System.DefaultWorkingDirectory)/reports'
        ArtifactName: 'DAST-Reports'
```

**Blocking Criteria:**

| Risk Level | Action |
|------------|--------|
| High | Block deployment to Production |
| Medium | Require security team approval |
| Low | Document and track |
| Informational | Log only |

### 2.3 Software Composition Analysis (SCA)

**Tooling:** Dependabot (GitHub) / WhiteSource Bolt / Snyk

**Pipeline Integration:**

```yaml
# SCA stage
- stage: SCA
  jobs:
  - job: DependencyCheck
    steps:
    - task: dependency-check-build-task@6
      inputs:
        projectName: '$(Build.Repository.Name)'
        scanPath: '$(Build.SourcesDirectory)'
        format: 'HTML,JSON'
        failOnCVSS: '7'  # Fail on High/Critical
        enableExperimental: true

    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Common.TestResultsDirectory)/dependency-check'
        ArtifactName: 'SCA-Reports'
```

**Vulnerability SLAs:**

| Severity | CVSS Score | Remediation SLA |
|----------|------------|-----------------|
| Critical | 9.0 - 10.0 | 24 hours |
| High | 7.0 - 8.9 | 7 days |
| Medium | 4.0 - 6.9 | 30 days |
| Low | 0.1 - 3.9 | 90 days |

### 2.4 Patch Management

| Component | Scan Frequency | Patch Window |
|-----------|----------------|--------------|
| Container base images | Daily | Weekly (non-prod), Monthly (prod) |
| OS packages | Daily | Weekly |
| Application dependencies | On each build | With code changes |
| Infrastructure (IaC) | Weekly | Monthly |

---

## 3. Supply Chain Security

### 3.1 Software Bill of Materials (SBOM)

**Generation (in pipeline):**

```yaml
- task: Bash@3
  displayName: 'Generate SBOM'
  inputs:
    targetType: 'inline'
    script: |
      # Install SBOM tool
      dotnet tool install --global Microsoft.Sbom.DotNetTool

      # Generate SBOM in SPDX format
      sbom-tool generate \
        -b $(Build.ArtifactStagingDirectory) \
        -bc $(Build.SourcesDirectory) \
        -pn $(Build.Repository.Name) \
        -pv $(Build.BuildNumber) \
        -ps "143it" \
        -nsb "https://143it.com/sbom"

- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.ArtifactStagingDirectory)/_manifest'
    ArtifactName: 'SBOM'
```

**SBOM Storage:**

- Store with each release artifact in Azure Artifacts
- Retain for minimum 3 years
- Include in release notes

### 3.2 Artifact Signing

**Container Image Signing (Notation/Cosign):**

```yaml
- task: AzureCLI@2
  displayName: 'Sign Container Image'
  inputs:
    azureSubscription: 'Production'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Sign with Azure Key Vault key
      notation sign \
        --key "https://$KEYVAULT.vault.azure.net/keys/image-signing-key" \
        $(ACR_NAME).azurecr.io/$(IMAGE_NAME):$(TAG)

      # Verify signature
      notation verify \
        $(ACR_NAME).azurecr.io/$(IMAGE_NAME):$(TAG)
```

**Verification Policy:**

```yaml
# Admission policy - only deploy signed images
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-signature-verification
webhooks:
  - name: verify.notation.io
    rules:
      - operations: ["CREATE", "UPDATE"]
        resources: ["pods"]
```

### 3.3 Dependency Pinning

**Requirements:**

- [ ] Pin all direct dependencies to exact versions
- [ ] Use lock files (package-lock.json, yarn.lock, Pipfile.lock)
- [ ] Verify checksums of downloaded packages
- [ ] Use private artifact feeds for approved packages

**Azure Artifacts Upstream Sources:**

```bash
# Configure upstream source with package approval
az artifacts universal package publish \
  --organization https://dev.azure.com/143it \
  --feed InternalPackages \
  --name approved-package \
  --version 1.0.0 \
  --path ./package
```

### 3.4 Build Provenance

**SLSA Level 2 Compliance:**

```yaml
# Generate build provenance
- task: Bash@3
  displayName: 'Generate Provenance'
  inputs:
    targetType: 'inline'
    script: |
      cat > provenance.json << EOF
      {
        "builder": {
          "id": "https://dev.azure.com/143it/_build"
        },
        "buildType": "https://dev.azure.com/143it/BuildType/v1",
        "invocation": {
          "configSource": {
            "uri": "$(Build.Repository.Uri)",
            "digest": {"sha1": "$(Build.SourceVersion)"},
            "entryPoint": "azure-pipelines.yml"
          }
        },
        "metadata": {
          "buildInvocationId": "$(Build.BuildId)",
          "buildStartedOn": "$(Build.StartTime)",
          "completeness": {
            "parameters": true,
            "environment": true,
            "materials": true
          }
        },
        "materials": [
          {
            "uri": "$(Build.Repository.Uri)",
            "digest": {"sha1": "$(Build.SourceVersion)"}
          }
        ]
      }
      EOF
```

---

## 4. Network Security

### 4.1 Network Segmentation

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Virtual Network                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Web Tier  │  │   App Tier  │  │  Data Tier  │          │
│  │  (Public)   │──│  (Private)  │──│  (Private)  │          │
│  │ NSG: web-nsg│  │ NSG: app-nsg│  │ NSG: db-nsg │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│         │                │                │                  │
│  ┌──────┴────────────────┴────────────────┴──────┐          │
│  │              Private Endpoints                 │          │
│  │  - Azure SQL  - Key Vault  - Storage          │          │
│  └───────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Network Security Groups (NSGs)

**Web Tier NSG:**

| Priority | Direction | Source | Destination | Port | Action |
|----------|-----------|--------|-------------|------|--------|
| 100 | Inbound | Internet | VNet | 443 | Allow |
| 110 | Inbound | AzureLoadBalancer | VNet | Any | Allow |
| 4096 | Inbound | Any | Any | Any | Deny |

**App Tier NSG:**

| Priority | Direction | Source | Destination | Port | Action |
|----------|-----------|--------|-------------|------|--------|
| 100 | Inbound | WebSubnet | AppSubnet | 8080 | Allow |
| 110 | Inbound | AzureDevOps | AppSubnet | 443 | Allow |
| 4096 | Inbound | Any | Any | Any | Deny |

**Data Tier NSG:**

| Priority | Direction | Source | Destination | Port | Action |
|----------|-----------|--------|-------------|------|--------|
| 100 | Inbound | AppSubnet | DataSubnet | 1433 | Allow |
| 4096 | Inbound | Any | Any | Any | Deny |

### 4.3 Private Endpoints

**Required Private Endpoints:**

| Service | Private Endpoint | DNS Zone |
|---------|------------------|----------|
| Azure SQL | pe-sql-prod | privatelink.database.windows.net |
| Key Vault | pe-kv-prod | privatelink.vaultcore.azure.net |
| Storage Account | pe-storage-prod | privatelink.blob.core.windows.net |
| Container Registry | pe-acr-prod | privatelink.azurecr.io |

**Implementation:**

```bash
# Create private endpoint for Azure SQL
az network private-endpoint create \
  --name pe-sql-prod \
  --resource-group $RG \
  --vnet-name $VNET \
  --subnet DataSubnet \
  --private-connection-resource-id $SQL_SERVER_ID \
  --group-id sqlServer \
  --connection-name sql-private-connection

# Configure private DNS zone
az network private-dns zone create \
  --resource-group $RG \
  --name privatelink.database.windows.net

az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name privatelink.database.windows.net \
  --name sql-dns-link \
  --virtual-network $VNET \
  --registration-enabled false
```

### 4.4 Azure DevOps Network Isolation

**IP Allow Listing:**

```bash
# Restrict Azure DevOps org to corporate IPs
# Via Organization Settings > Security > Policies > IP Allow List
Corporate Office: 203.0.113.0/24
VPN Gateway: 198.51.100.0/24
Azure Pipeline Agents: 10.0.1.0/24 (self-hosted)
```

**Self-Hosted Agent Network Configuration:**

```bash
# Agent subnet with private connectivity only
az network vnet subnet create \
  --name AgentSubnet \
  --resource-group $RG \
  --vnet-name $VNET \
  --address-prefixes 10.0.1.0/24 \
  --service-endpoints Microsoft.KeyVault Microsoft.Sql Microsoft.Storage
```

---

## 5. Container Security

### 5.1 Base Image Policy

**Approved Base Images:**

| Language/Runtime | Approved Image | Source |
|------------------|----------------|--------|
| .NET | mcr.microsoft.com/dotnet/aspnet:8.0-alpine | Microsoft |
| Node.js | mcr.microsoft.com/cbl-mariner/base/nodejs:18 | Microsoft |
| Python | mcr.microsoft.com/cbl-mariner/base/python:3.11 | Microsoft |
| Java | mcr.microsoft.com/openjdk/jdk:17-mariner | Microsoft |

**Base Image Requirements:**

- [ ] Use distroless or minimal images (Alpine, Mariner)
- [ ] No root user in container
- [ ] Read-only filesystem where possible
- [ ] No shell access in production images

### 5.2 Container Image Scanning

**Pipeline Integration (Trivy):**

```yaml
- task: Bash@3
  displayName: 'Scan Container Image'
  inputs:
    targetType: 'inline'
    script: |
      # Scan for vulnerabilities
      trivy image \
        --severity CRITICAL,HIGH \
        --exit-code 1 \
        --ignore-unfixed \
        --format json \
        --output trivy-results.json \
        $(IMAGE_NAME):$(TAG)

      # Scan for misconfigurations
      trivy config \
        --severity CRITICAL,HIGH \
        --exit-code 1 \
        ./Dockerfile

- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'trivy-results.xml'
```

**Blocking Criteria:**

| Finding | Action |
|---------|--------|
| Critical CVE | Block build |
| High CVE (no fix available) | Require exception approval |
| Root user | Block build |
| Secrets in image | Block build |

### 5.3 Registry Security

**Azure Container Registry Configuration:**

```bash
# Enable content trust
az acr config content-trust update \
  --registry $ACR_NAME \
  --status enabled

# Enable vulnerability scanning
az acr task create \
  --registry $ACR_NAME \
  --name scanOnPush \
  --image-scan-on-push true

# Quarantine policy for vulnerable images
az acr config quarantine update \
  --registry $ACR_NAME \
  --status enabled
```

### 5.4 Runtime Security

**Pod Security Standards:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Security Context (Required):**

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

---

## 6. Secrets Management Procedures

### 6.1 Secret Rotation Automation

**Service Principal Rotation (Azure DevOps Pipeline):**

```yaml
schedules:
- cron: "0 2 1 */3 *"  # Quarterly at 2 AM on 1st
  displayName: 'Quarterly SP Rotation'
  branches:
    include:
    - main

stages:
- stage: RotateSecrets
  jobs:
  - job: RotateServicePrincipal
    steps:
    - task: AzureCLI@2
      inputs:
        azureSubscription: 'Admin-Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Generate new credential
          NEW_SECRET=$(az ad sp credential reset \
            --id $SP_APP_ID \
            --credential-description "Rotated-$(date +%Y%m%d)" \
            --query password -o tsv)

          # Update Key Vault
          az keyvault secret set \
            --vault-name $KEYVAULT \
            --name sp-client-secret \
            --value "$NEW_SECRET"

          # Update Azure DevOps service connection
          az devops service-endpoint update \
            --id $SERVICE_ENDPOINT_ID \
            --org https://dev.azure.com/143it \
            --project Head_Office \
            --authorization-parameters "serviceprincipalkey=$NEW_SECRET"
```

### 6.2 Leaked Secret Response

**Immediate Actions (< 15 minutes):**

1. Revoke the compromised secret
2. Rotate all related credentials
3. Check audit logs for unauthorized access
4. Notify security team

**Response Procedure:**

```bash
# 1. Revoke PAT immediately
az devops security token personal-access-tokens delete \
  --organization https://dev.azure.com/143it \
  --id $TOKEN_ID

# 2. Disable service principal
az ad sp update --id $SP_ID --set accountEnabled=false

# 3. Query audit logs
az monitor activity-log list \
  --start-time $(date -d '-24 hours' -Iseconds) \
  --caller $COMPROMISED_IDENTITY \
  --output table

# 4. Generate new credentials (after investigation)
az ad sp credential reset --id $SP_ID
```

### 6.3 Secret Access Logging

**Key Vault Diagnostic Settings:**

```bash
az monitor diagnostic-settings create \
  --name kv-secret-audit \
  --resource $KEYVAULT_ID \
  --logs '[
    {"category":"AuditEvent","enabled":true,"retentionPolicy":{"days":365,"enabled":true}}
  ]' \
  --workspace $LOG_ANALYTICS_ID

# Alert on secret access
az monitor scheduled-query create \
  --name "High-Volume-Secret-Access" \
  --resource-group $RG \
  --scopes $LOG_ANALYTICS_ID \
  --condition "count > 100" \
  --condition-query "AzureDiagnostics | where ResourceType == 'VAULTS' | where OperationName == 'SecretGet' | summarize count() by CallerIPAddress | where count_ > 100" \
  --evaluation-frequency 5m \
  --window-size 15m \
  --severity 2 \
  --action-groups $ACTION_GROUP_ID
```

---

## 7. Access Control Procedures

### 7.1 Just-In-Time (JIT) Access

**Azure PIM Configuration:**

| Role | Eligible Duration | Activation Max | Approval Required |
|------|-------------------|----------------|-------------------|
| Contributor (Prod) | 8 hours | 4 hours | Yes (Manager) |
| Key Vault Admin | 8 hours | 2 hours | Yes (Security) |
| SQL Admin | 8 hours | 2 hours | Yes (DBA Lead) |
| DevOps Admin | Permanent (limited users) | N/A | N/A |

### 7.2 Break-Glass Procedures

**Emergency Access Account:**

- Stored in physical safe (two-person access)
- Cloud-only account (not federated)
- Excluded from Conditional Access (monitored separately)
- Password rotation: After every use + quarterly
- Usage triggers immediate security review

**Break-Glass Process:**

1. Obtain credentials from safe (requires 2 authorized personnel)
2. Log incident number before use
3. Perform emergency action
4. Log out immediately
5. Reset credentials
6. Complete incident report within 4 hours

### 7.3 Offboarding Procedure

| Timeline | Action | Owner |
|----------|--------|-------|
| Day 0 | Disable Azure AD account | IT |
| Day 0 | Revoke all PATs | DevOps Admin |
| Day 0 | Remove from Azure DevOps groups | Project Admin |
| Day 0 | Rotate any shared secrets employee had access to | Security |
| Day 1 | Review recent commits/changes | Team Lead |
| Day 7 | Archive or reassign work items | Manager |
| Day 30 | Delete Azure AD account | IT |

---

## 8. Compliance Control Mappings

### 8.1 SOC 2 Type II

| Trust Service Criteria | Control | Implementation | Document |
|------------------------|---------|----------------|----------|
| CC6.1 | Logical access | Azure AD + MFA | security_baseline.md §1-2 |
| CC6.2 | Access provisioning | Group-based access | security_baseline.md §1 |
| CC6.3 | Access removal | Offboarding procedure | This doc §7.3 |
| CC6.6 | Encryption | TLS 1.2 + AES-256 | This doc §1 |
| CC6.7 | Transmission security | HTTPS/TLS | This doc §1.2 |
| CC7.1 | Change management | PR reviews + approvals | security_baseline.md §4 |
| CC7.2 | System monitoring | Azure Monitor + alerts | monitoring_plan.md |
| CC8.1 | Incident response | IR procedures | security_baseline.md §7 |

### 8.2 ISO 27001

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| A.9.1 | Access control policy | security_baseline.md |
| A.9.2 | User access management | Azure AD groups |
| A.10.1 | Cryptographic controls | This doc §1 |
| A.12.4 | Logging and monitoring | monitoring_plan.md |
| A.12.6 | Vulnerability management | This doc §2 |
| A.14.2 | Secure development | testing_strategy.md |
| A.16.1 | Incident management | This doc §6.2, monitoring_plan.md |
| A.17.1 | Business continuity | disaster_recovery_plan.md |

### 8.3 HIPAA (If Applicable)

| Safeguard | Requirement | Implementation |
|-----------|-------------|----------------|
| 164.312(a)(1) | Access control | Azure AD + RBAC |
| 164.312(b) | Audit controls | Audit streaming + Log Analytics |
| 164.312(c)(1) | Integrity | Checksums + artifact signing |
| 164.312(d) | Authentication | MFA required |
| 164.312(e)(1) | Transmission security | TLS 1.2+ |
| 164.312(e)(2) | Encryption | At-rest + in-transit |

---

## 9. Security Scanning Pipeline (Complete)

```yaml
# security-scan-template.yml
parameters:
- name: projectPath
  type: string
- name: imageName
  type: string
  default: ''

stages:
- stage: SecurityScanning
  jobs:
  - job: SAST
    steps:
    - template: steps/sonar-scan.yml
      parameters:
        projectPath: ${{ parameters.projectPath }}

  - job: SCA
    steps:
    - template: steps/dependency-check.yml
      parameters:
        projectPath: ${{ parameters.projectPath }}

  - job: SecretsScan
    steps:
    - task: Bash@3
      displayName: 'Detect Secrets'
      inputs:
        targetType: 'inline'
        script: |
          pip install detect-secrets
          detect-secrets scan ${{ parameters.projectPath }} \
            --baseline .secrets.baseline \
            --exclude-files '\.git|\.env\.example' \
            > secrets-results.json

          # Fail if new secrets found
          if [ $(jq '.results | length' secrets-results.json) -gt 0 ]; then
            echo "##vso[task.logissue type=error]New secrets detected!"
            exit 1
          fi

  - job: ContainerScan
    condition: ne('${{ parameters.imageName }}', '')
    steps:
    - template: steps/trivy-scan.yml
      parameters:
        imageName: ${{ parameters.imageName }}

  - job: IaCScan
    steps:
    - task: Bash@3
      displayName: 'Scan IaC (Checkov)'
      inputs:
        targetType: 'inline'
        script: |
          pip install checkov
          checkov -d ./infrastructure \
            --framework terraform bicep arm \
            --output junitxml \
            --output-file checkov-results.xml \
            --soft-fail-on MEDIUM,LOW

    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: 'checkov-results.xml'
```

---

## 10. Compliance Audit Checklist

### Quarterly Review

- [ ] Review and attest access for all privileged accounts
- [ ] Verify MFA enforcement (no exceptions without documented approval)
- [ ] Review PAT usage and revoke unused tokens
- [ ] Audit service connection permissions
- [ ] Review and update security group memberships
- [ ] Verify encryption key rotation occurred
- [ ] Review vulnerability scan results and remediation status
- [ ] Test disaster recovery procedures
- [ ] Review audit logs for anomalies

### Annual Review

- [ ] Penetration test (external vendor)
- [ ] Full compliance assessment against target frameworks
- [ ] Security policy review and update
- [ ] Incident response tabletop exercise
- [ ] Business continuity plan test
- [ ] Third-party vendor security assessment
- [ ] Security awareness training completion verification
