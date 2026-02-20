# Deployment Strategy — 143it Azure DevOps

> **Related:** [Rollback Procedures](rollback_procedures.md) | [Testing Strategy](testing_strategy.md) | [Change Management](change_management.md)

This document defines deployment patterns, promotion gates, and release procedures for the 143it DevOps environment.

---

## Table of Contents

1. [Deployment Patterns](#1-deployment-patterns)
2. [Environment Promotion](#2-environment-promotion)
3. [Promotion Gates](#3-promotion-gates)
4. [Deployment Windows](#4-deployment-windows)
5. [Pre-Deployment Checklist](#5-pre-deployment-checklist)
6. [Post-Deployment Validation](#6-post-deployment-validation)
7. [Pipeline Templates](#7-pipeline-templates)

---

## 1. Deployment Patterns

### 1.1 Strategy Selection Matrix

| Criteria | Rolling | Blue-Green | Canary |
|----------|---------|------------|--------|
| Zero downtime | Yes | Yes | Yes |
| Instant rollback | No (gradual) | Yes (swap) | Yes (traffic shift) |
| Infrastructure cost | Low | 2x (during deploy) | 1.1-1.5x |
| Complexity | Low | Medium | High |
| Best for | Stateless apps | Critical services | High-risk changes |
| Risk exposure | Gradual | None until swap | Controlled % |

### 1.2 Rolling Deployment

**How it works:**
- Replaces instances gradually (e.g., 25% at a time)
- Old and new versions run simultaneously during rollout
- Automatic rollback if health checks fail

**When to use:**
- Standard deployments with low risk
- Stateless applications
- When infrastructure cost is a concern

**Azure Pipelines Implementation:**

```yaml
# rolling-deployment.yml
stages:
- stage: Deploy
  jobs:
  - deployment: RollingDeploy
    environment: production
    strategy:
      rolling:
        maxParallel: 25%  # Deploy 25% at a time
        preDeploy:
          steps:
          - script: echo "Preparing deployment"
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Production'
              appType: 'webApp'
              appName: '$(appName)'
              package: '$(Pipeline.Workspace)/drop/*.zip'
        routeTraffic:
          steps:
          - script: echo "Routing traffic to new instances"
        postRouteTraffic:
          steps:
          - task: Bash@3
            inputs:
              targetType: 'inline'
              script: |
                # Health check
                response=$(curl -s -o /dev/null -w "%{http_code}" https://$(appUrl)/health)
                if [ $response != "200" ]; then
                  echo "Health check failed"
                  exit 1
                fi
        on:
          failure:
            steps:
            - script: echo "Rolling back deployment"
          success:
            steps:
            - script: echo "Deployment successful"
```

**Kubernetes Rolling Update:**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra pods during update
      maxUnavailable: 0  # Zero downtime
  template:
    spec:
      containers:
      - name: myapp
        image: myacr.azurecr.io/myapp:v2
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
```

### 1.3 Blue-Green Deployment

**How it works:**
- Two identical environments: Blue (current) and Green (new)
- Deploy to Green while Blue serves traffic
- Swap traffic instantly when Green is validated
- Keep Blue available for instant rollback

**When to use:**
- Mission-critical services requiring instant rollback
- Database schema changes (with compatibility window)
- Major version upgrades

**Azure App Service Implementation:**

```yaml
# blue-green-deployment.yml
stages:
- stage: DeployToGreen
  jobs:
  - deployment: DeployStaging
    environment: production-staging  # Green slot
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Production'
              appType: 'webApp'
              appName: '$(appName)'
              deployToSlotOrASE: true
              slotName: 'staging'  # Green slot
              package: '$(Pipeline.Workspace)/drop/*.zip'

- stage: ValidateGreen
  dependsOn: DeployToGreen
  jobs:
  - job: SmokeTests
    steps:
    - task: Bash@3
      displayName: 'Run smoke tests against Green'
      inputs:
        targetType: 'inline'
        script: |
          # Test staging slot
          npm run test:smoke -- --url https://$(appName)-staging.azurewebsites.net

    - task: Bash@3
      displayName: 'Load test Green'
      inputs:
        targetType: 'inline'
        script: |
          # Verify Green can handle load
          k6 run --vus 50 --duration 2m load-test.js

- stage: SwapSlots
  dependsOn: ValidateGreen
  jobs:
  - deployment: SwapToProduction
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceManage@0
            displayName: 'Swap staging to production'
            inputs:
              azureSubscription: 'Production'
              action: 'Swap Slots'
              webAppName: '$(appName)'
              sourceSlot: 'staging'
              targetSlot: 'production'
              preserveVnet: true
```

**Traffic Manager Blue-Green:**

```bash
# Switch traffic at DNS level
az network traffic-manager endpoint update \
  --resource-group $RG \
  --profile-name $TM_PROFILE \
  --name blue-endpoint \
  --type azureEndpoints \
  --endpoint-status Disabled

az network traffic-manager endpoint update \
  --resource-group $RG \
  --profile-name $TM_PROFILE \
  --name green-endpoint \
  --type azureEndpoints \
  --endpoint-status Enabled
```

### 1.4 Canary Deployment

**How it works:**
- Deploy new version to small subset of infrastructure
- Route small percentage of traffic to new version
- Monitor for errors/degradation
- Gradually increase traffic if metrics are good
- Full rollout or rollback based on results

**When to use:**
- High-risk changes
- Changes affecting user experience
- A/B testing deployments
- When you need real user validation

**Azure Front Door Canary:**

```yaml
# canary-deployment.yml
parameters:
- name: canaryPercentage
  type: number
  default: 10

stages:
- stage: DeployCanary
  jobs:
  - deployment: CanaryDeploy
    environment: production-canary
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Production'
              appName: '$(appName)-canary'
              package: '$(Pipeline.Workspace)/drop/*.zip'

- stage: RouteCanaryTraffic
  dependsOn: DeployCanary
  jobs:
  - job: ConfigureTraffic
    steps:
    - task: AzureCLI@2
      displayName: 'Route ${{ parameters.canaryPercentage }}% to canary'
      inputs:
        azureSubscription: 'Production'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az afd route update \
            --resource-group $RG \
            --profile-name $AFD_PROFILE \
            --endpoint-name $ENDPOINT \
            --route-name main-route \
            --origin-group canary-origins

- stage: MonitorCanary
  dependsOn: RouteCanaryTraffic
  jobs:
  - job: MonitorMetrics
    pool: server  # Agentless job
    steps:
    - task: ManualValidation@0
      displayName: 'Monitor canary for 30 minutes'
      inputs:
        notifyUsers: 'devops@143it.com'
        instructions: |
          Monitor the following metrics for 30 minutes:
          - Error rate: Should be < 1%
          - Latency p95: Should be < 200ms
          - No new error types

          Approve to proceed with full rollout.
          Reject to rollback canary.
        onTimeout: 'reject'
        timeout: '30'

- stage: FullRollout
  dependsOn: MonitorCanary
  condition: succeeded()
  jobs:
  - job: RolloutToAll
    steps:
    - task: AzureCLI@2
      displayName: 'Route 100% to new version'
      inputs:
        azureSubscription: 'Production'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Deploy to all instances
          az webapp deployment slot swap \
            --resource-group $RG \
            --name $(appName) \
            --slot canary \
            --target-slot production
```

**Kubernetes Canary with Flagger:**

```yaml
# canary.yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  progressDeadlineSeconds: 600
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
```

---

## 2. Environment Promotion

### 2.1 Environment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ARTIFACT BUILD                           │
│                    (CI Pipeline)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      DEVELOPMENT                            │
│  • Auto-deploy on PR merge                                  │
│  • Integration tests                                        │
│  • No approval required                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │   QA Gate     │
                    │  (Automated)  │
                    └───────┬───────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       STAGING                               │
│  • Full test suite execution                                │
│  • Performance testing                                      │
│  • Security scanning                                        │
│  • UAT environment                                          │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │  Prod Gate    │
                    │  (Manual +    │
                    │   Automated)  │
                    └───────┬───────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      PRODUCTION                             │
│  • Canary or Blue-Green deployment                          │
│  • Health monitoring                                        │
│  • Auto-rollback on failure                                 │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Environment Configuration

| Environment | Purpose | Data | Auto-Deploy | Approval |
|-------------|---------|------|-------------|----------|
| Development | Integration testing | Synthetic | Yes (on merge) | None |
| Staging | UAT, performance | Anonymized prod | Yes (after Dev) | QA sign-off |
| Production | Live users | Production | Manual trigger | Change approval |

### 2.3 Artifact Promotion Rules

**Immutable Artifacts:**
- Build once, deploy everywhere
- Same artifact moves through all environments
- Only configuration changes per environment

```yaml
# Artifact versioning
variables:
  majorVersion: 1
  minorVersion: 0
  patchVersion: $[counter(format('{0}.{1}', variables['majorVersion'], variables['minorVersion']), 0)]
  version: $(majorVersion).$(minorVersion).$(patchVersion)

steps:
- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.ArtifactStagingDirectory)'
    ArtifactName: 'drop-$(version)'
    publishLocation: 'Container'
```

---

## 3. Promotion Gates

### 3.1 Development → Staging

**Automated Gates:**

| Gate | Criteria | Blocking |
|------|----------|----------|
| Build success | All builds pass | Yes |
| Unit tests | 100% pass, ≥80% coverage | Yes |
| Integration tests | 100% pass | Yes |
| SAST scan | 0 critical/high | Yes |
| SCA scan | 0 critical (CVSS ≥9) | Yes |

**Pipeline Implementation:**

```yaml
- stage: PromoteToStaging
  dependsOn:
  - Build
  - UnitTests
  - IntegrationTests
  - SecurityScan
  condition: |
    and(
      succeeded('Build'),
      succeeded('UnitTests'),
      succeeded('IntegrationTests'),
      succeeded('SecurityScan')
    )
```

### 3.2 Staging → Production

**Automated Gates:**

| Gate | Criteria | Blocking |
|------|----------|----------|
| All staging tests pass | E2E, performance, security | Yes |
| Performance baseline | p95 latency ≤ 200ms | Yes |
| Security scan | 0 critical/high | Yes |
| No open blockers | Jira/Azure Boards query | Yes |
| Minimum soak time | 4 hours in staging | Yes |

**Manual Gates:**

| Gate | Approver | SLA |
|------|----------|-----|
| QA sign-off | QA Lead | Required |
| Product approval | Product Manager | Required for features |
| Change approval | CAB or On-call Lead | Required |

**Pipeline Implementation:**

```yaml
- stage: ProductionGate
  dependsOn: StagingValidation
  jobs:
  - job: AutomatedChecks
    steps:
    - task: AzureCLI@2
      displayName: 'Check deployment blockers'
      inputs:
        azureSubscription: 'Production'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Check for open blockers in Azure Boards
          blockers=$(az boards query \
            --wiql "SELECT [ID] FROM WorkItems WHERE [Work Item Type] = 'Bug' AND [Priority] = 1 AND [State] = 'Active'" \
            --org https://dev.azure.com/143it \
            --project Head_Office \
            --query "length(@)")

          if [ "$blockers" -gt "0" ]; then
            echo "##vso[task.logissue type=error]$blockers open blockers found"
            exit 1
          fi

    - task: Bash@3
      displayName: 'Verify soak time'
      inputs:
        targetType: 'inline'
        script: |
          # Check staging deployment timestamp
          staging_deploy_time=$(az webapp deployment list \
            --resource-group $RG \
            --name $(appName)-staging \
            --query "[0].deployedAt" -o tsv)

          hours_since_deploy=$(( ($(date +%s) - $(date -d "$staging_deploy_time" +%s)) / 3600 ))

          if [ "$hours_since_deploy" -lt "4" ]; then
            echo "##vso[task.logissue type=error]Minimum 4 hour soak time not met"
            exit 1
          fi

  - job: ManualApproval
    dependsOn: AutomatedChecks
    pool: server
    steps:
    - task: ManualValidation@0
      inputs:
        notifyUsers: |
          qa-lead@143it.com
          change-approvers@143it.com
        instructions: |
          ## Production Deployment Approval

          **Version:** $(Build.BuildNumber)
          **Changes:** [View PR]($(prUrl))

          ### Checklist
          - [ ] QA sign-off complete
          - [ ] Release notes reviewed
          - [ ] Rollback plan confirmed
          - [ ] On-call team notified

          Approve to deploy to production.
```

### 3.3 Emergency Deployment Gates

For critical hotfixes, reduced gates apply:

| Gate | Standard | Emergency |
|------|----------|-----------|
| Full test suite | Required | Smoke tests only |
| Performance testing | Required | Waived |
| Soak time | 4 hours | Waived |
| QA sign-off | Required | Post-deploy review |
| Change approval | CAB | On-call Lead only |

**Emergency flag in pipeline:**

```yaml
parameters:
- name: isEmergency
  type: boolean
  default: false

stages:
- stage: ProductionGate
  condition: |
    or(
      eq('${{ parameters.isEmergency }}', false),
      succeeded('SmokeTests')
    )
```

---

## 4. Deployment Windows

### 4.1 Standard Deployment Windows

| Day | Window (UTC) | Local (EST) | Type |
|-----|--------------|-------------|------|
| Tuesday | 14:00 - 18:00 | 09:00 - 13:00 | Standard |
| Thursday | 14:00 - 18:00 | 09:00 - 13:00 | Standard |
| Saturday | 10:00 - 14:00 | 05:00 - 09:00 | Maintenance |

### 4.2 Blackout Periods

| Period | Dates | Reason |
|--------|-------|--------|
| Month-end | Last 3 business days | Financial close |
| Quarter-end | Last week of quarter | Reporting |
| Holiday freeze | Dec 15 - Jan 5 | Reduced staffing |
| Major events | As announced | Marketing campaigns |

### 4.3 After-Hours Deployment

Requirements for deployments outside standard windows:

- [ ] Emergency classification approved
- [ ] On-call engineer available
- [ ] Rollback tested and ready
- [ ] Stakeholder notification sent
- [ ] Post-deployment monitoring plan

---

## 5. Pre-Deployment Checklist

### 5.1 Standard Deployment

```markdown
## Pre-Deployment Checklist

### Code & Testing
- [ ] All CI checks passing
- [ ] Code review completed and approved
- [ ] Unit tests passing (≥80% coverage)
- [ ] Integration tests passing
- [ ] E2E tests passing in staging

### Security
- [ ] SAST scan: 0 critical/high findings
- [ ] SCA scan: No new critical vulnerabilities
- [ ] Secrets scan: No exposed secrets
- [ ] Security review (if required)

### Documentation
- [ ] Release notes prepared
- [ ] API documentation updated (if applicable)
- [ ] Runbook updated (if applicable)

### Operational Readiness
- [ ] Monitoring dashboards ready
- [ ] Alerts configured
- [ ] On-call engineer aware
- [ ] Rollback procedure confirmed

### Approvals
- [ ] QA sign-off
- [ ] Product approval (features)
- [ ] Change approval
```

### 5.2 Database Migration Checklist

```markdown
## Database Migration Checklist

### Pre-Migration
- [ ] Migration tested in staging with production-like data
- [ ] Backward compatibility verified
- [ ] Rollback migration tested
- [ ] Backup completed immediately before migration
- [ ] Estimated migration time calculated
- [ ] Maintenance window scheduled (if needed)

### Migration Execution
- [ ] Notify stakeholders of maintenance
- [ ] Run migration in transaction
- [ ] Verify row counts post-migration
- [ ] Run application smoke tests

### Rollback Criteria
- Migration fails: Immediate rollback
- Data validation fails: Assess and decide
- Application errors increase: Rollback within 15 min
```

---

## 6. Post-Deployment Validation

### 6.1 Health Check Sequence

```
T+0:00   Deploy complete
    │
    ├── Readiness probe passing
    ├── Liveness probe passing
    │
T+0:05   Initial health checks
    │
    ├── /health endpoint returns 200
    ├── /ready endpoint returns 200
    ├── Version endpoint shows correct version
    │
T+0:15   Smoke tests
    │
    ├── Login flow works
    ├── Core features functional
    ├── External integrations responding
    │
T+0:30   Metrics validation
    │
    ├── Error rate < baseline + 0.5%
    ├── Latency p95 < baseline + 10%
    ├── No new error types
    │
T+1:00   Extended monitoring
    │
    ├── Continue monitoring for anomalies
    ├── Scale-out responding correctly
    └── No memory leaks observed
```

### 6.2 Automated Validation Script

```bash
#!/bin/bash
# post-deploy-validation.sh

APP_URL=$1
EXPECTED_VERSION=$2

echo "=== Post-Deployment Validation ==="

# Health check
echo "Checking health endpoint..."
health_status=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")
if [ "$health_status" != "200" ]; then
  echo "FAIL: Health check returned $health_status"
  exit 1
fi
echo "PASS: Health check"

# Version check
echo "Checking version..."
actual_version=$(curl -s "$APP_URL/version" | jq -r '.version')
if [ "$actual_version" != "$EXPECTED_VERSION" ]; then
  echo "FAIL: Expected version $EXPECTED_VERSION, got $actual_version"
  exit 1
fi
echo "PASS: Version check"

# Smoke test - Login
echo "Testing login flow..."
login_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$APP_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"smoke-test","password":"$SMOKE_TEST_PASSWORD"}')
if [ "$login_status" != "200" ]; then
  echo "FAIL: Login returned $login_status"
  exit 1
fi
echo "PASS: Login flow"

echo "=== All validations passed ==="
```

### 6.3 Monitoring Dashboard Checklist

After deployment, verify these metrics on dashboard:

| Metric | Expected | Alert If |
|--------|----------|----------|
| Error rate | < 0.1% | > 1% |
| p50 latency | < 50ms | > 100ms |
| p95 latency | < 200ms | > 500ms |
| p99 latency | < 500ms | > 1000ms |
| CPU usage | < 70% | > 85% |
| Memory usage | < 70% | > 85% |
| Active connections | Baseline ±20% | ±50% |
| Request rate | Baseline ±10% | ±30% |

---

## 7. Pipeline Templates

### 7.1 Standard Release Pipeline

See [templates/pipeline-release-template.yml](templates/pipeline-release-template.yml) for the complete template.

### 7.2 Deployment Strategy Selection

```yaml
# deploy-strategy-selector.yml
parameters:
- name: deploymentStrategy
  type: string
  default: 'rolling'
  values:
  - rolling
  - blue-green
  - canary

- name: canaryPercentage
  type: number
  default: 10

stages:
- ${{ if eq(parameters.deploymentStrategy, 'rolling') }}:
  - template: strategies/rolling.yml

- ${{ if eq(parameters.deploymentStrategy, 'blue-green') }}:
  - template: strategies/blue-green.yml

- ${{ if eq(parameters.deploymentStrategy, 'canary') }}:
  - template: strategies/canary.yml
    parameters:
      percentage: ${{ parameters.canaryPercentage }}
```

### 7.3 Deployment Notification

```yaml
# notify-deployment.yml
steps:
- task: Bash@3
  displayName: 'Send deployment notification'
  inputs:
    targetType: 'inline'
    script: |
      curl -X POST "$TEAMS_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{
          "@type": "MessageCard",
          "themeColor": "0076D7",
          "summary": "Deployment to $(environment)",
          "sections": [{
            "activityTitle": "$(Build.DefinitionName) deployed to $(environment)",
            "facts": [
              {"name": "Version", "value": "$(Build.BuildNumber)"},
              {"name": "Deployed by", "value": "$(Build.RequestedFor)"},
              {"name": "Repository", "value": "$(Build.Repository.Name)"}
            ],
            "markdown": true
          }]
        }'
```
