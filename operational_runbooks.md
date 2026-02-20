# Operational Runbooks — 143it Azure DevOps

> **Related:** [Monitoring Plan](monitoring_plan.md) | [Disaster Recovery](disaster_recovery_plan.md) | [Deployment Strategy](deployment_strategy.md)

This document provides step-by-step procedures for common operational scenarios. Each runbook is designed to be followed sequentially during an incident.

---

## Table of Contents

1. [Pipeline Failure Diagnosis](#1-pipeline-failure-diagnosis)
2. [Build Agent Issues](#2-build-agent-issues)
3. [Deployment Failures](#3-deployment-failures)
4. [Service Dependency Failures](#4-service-dependency-failures)
5. [On-Call Procedures](#5-on-call-procedures)
6. [Incident War Room](#6-incident-war-room)
7. [Common Error Reference](#7-common-error-reference)
8. [Log Locations & Analysis](#8-log-locations--analysis)
9. [Post-Incident Review](#9-post-incident-review)

---

## 1. Pipeline Failure Diagnosis

### 1.1 Initial Triage (< 5 minutes)

```
┌─────────────────────────────────────────────────────────────┐
│                    Pipeline Failed                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │ Check failure stage     │
              └─────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ┌─────────┐        ┌──────────┐        ┌─────────┐
   │  Build  │        │   Test   │        │ Deploy  │
   └─────────┘        └──────────┘        └─────────┘
        │                   │                   │
        ▼                   ▼                   ▼
   See §1.2            See §1.3            See §3
```

### 1.2 Build Stage Failures

**Step 1: Check build logs**

```bash
# Via Azure DevOps CLI
az pipelines runs show \
  --id $BUILD_ID \
  --org https://dev.azure.com/143it \
  --project Head_Office \
  --query "result"

# Get logs
az pipelines logs download \
  --id $BUILD_ID \
  --org https://dev.azure.com/143it \
  --project Head_Office \
  --path ./logs
```

**Step 2: Identify error category**

| Error Pattern | Likely Cause | Resolution |
|---------------|--------------|------------|
| `MSBUILD : error MSB4019` | Missing SDK/tools | Check agent capabilities |
| `error CS0234: does not exist` | Missing package reference | Run `dotnet restore` |
| `npm ERR! network` | Network/registry issue | Check agent network, retry |
| `COPY failed: file not found` | Docker context issue | Verify Dockerfile paths |
| `Out of memory` | Agent resource limits | Increase agent pool resources |

**Step 3: Common resolutions**

```bash
# Clear NuGet cache (package issues)
dotnet nuget locals all --clear

# Reset node_modules (npm issues)
rm -rf node_modules package-lock.json && npm install

# Check agent capabilities
az pipelines agent list \
  --pool-id $POOL_ID \
  --org https://dev.azure.com/143it \
  --query "[].{name:name,status:status,capabilities:systemCapabilities}"
```

### 1.3 Test Stage Failures

**Step 1: Download test results**

```bash
# Get test run details
az pipelines runs artifact download \
  --artifact-name "TestResults" \
  --run-id $BUILD_ID \
  --path ./test-results
```

**Step 2: Analyze failures**

| Test Type | Investigation Steps |
|-----------|---------------------|
| Unit tests | Check test output, verify mock data |
| Integration tests | Check external service connectivity |
| E2E tests | Check test environment health, screenshots |
| Security tests | Review vulnerability report |

**Step 3: Common test environment issues**

```bash
# Check if test database is accessible
az sql db show-connection-string \
  --server $SQL_SERVER \
  --name $TEST_DB \
  --client ado.net

# Verify test environment health
curl -s https://$TEST_ENV_URL/health | jq .

# Check for resource contention
az monitor metrics list \
  --resource $APP_SERVICE_ID \
  --metric "CpuPercentage,MemoryPercentage" \
  --interval PT1H
```

---

## 2. Build Agent Issues

### 2.1 Agent Offline

**Symptoms:** Pipeline queued indefinitely, agent shows offline

**Diagnosis:**

```bash
# Check agent status
az pipelines agent show \
  --agent-id $AGENT_ID \
  --pool-id $POOL_ID \
  --org https://dev.azure.com/143it

# Check agent VM status (if self-hosted)
az vm get-instance-view \
  --resource-group $RG \
  --name $AGENT_VM \
  --query "instanceView.statuses[1]"
```

**Resolution:**

```bash
# Restart agent service (SSH to agent VM)
sudo systemctl restart vsts-agent-*.service

# If VM is stopped
az vm start --resource-group $RG --name $AGENT_VM

# Reconfigure agent (if PAT expired)
./config.sh remove
./config.sh --unattended \
  --url https://dev.azure.com/143it \
  --auth pat \
  --token $NEW_PAT \
  --pool $POOL_NAME \
  --agent $AGENT_NAME
```

### 2.2 Agent Pool Exhausted

**Symptoms:** Pipeline queued, message "Waiting for an available agent"

**Diagnosis:**

```bash
# Check pool utilization
az pipelines pool show \
  --pool-id $POOL_ID \
  --org https://dev.azure.com/143it \
  --query "{name:name,size:size,isHosted:isHosted}"

# List running jobs
az pipelines runs list \
  --org https://dev.azure.com/143it \
  --project Head_Office \
  --status inProgress \
  --query "[].{id:id,pipeline:pipeline.name,startTime:startTime}"
```

**Resolution:**

| Scenario | Action |
|----------|--------|
| Temporary spike | Wait for running jobs to complete |
| Consistent overload | Scale up agent pool (add VMs) |
| Stuck job | Cancel stuck pipeline, investigate |
| Microsoft-hosted | Switch to larger pool or self-hosted |

```bash
# Cancel stuck build
az pipelines run cancel \
  --run-id $STUCK_BUILD_ID \
  --org https://dev.azure.com/143it \
  --project Head_Office

# Scale agent pool (VMSS)
az vmss scale \
  --resource-group $RG \
  --name $VMSS_NAME \
  --new-capacity 5
```

### 2.3 Agent Capability Missing

**Symptoms:** Pipeline fails with "No agent found with the following capabilities"

**Resolution:**

```bash
# List required capabilities from pipeline
az pipelines show \
  --id $PIPELINE_ID \
  --org https://dev.azure.com/143it \
  --query "configuration.demands"

# Add capability to agent (SSH to agent)
# For tools: install the required tool
sudo apt-get install -y dotnet-sdk-8.0

# Restart agent to detect new capabilities
sudo systemctl restart vsts-agent-*.service
```

---

## 3. Deployment Failures

### 3.1 Deployment Triage

```
┌─────────────────────────────────────────────────────────────┐
│                    Deployment Failed                        │
└─────────────────────────────────────────────────────────────┘
                            │
           What environment failed?
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ┌─────────┐        ┌──────────┐        ┌────────────┐
   │   Dev   │        │ Staging  │        │ Production │
   └─────────┘        └──────────┘        └────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
   Debug locally       Investigate          STOP!
   Fix and retry       See §3.2             See §3.3
```

### 3.2 Staging Deployment Issues

**Step 1: Check deployment logs**

```bash
# App Service deployment logs
az webapp log deployment show \
  --resource-group $RG \
  --name $APP_NAME

# Kubernetes deployment status
kubectl rollout status deployment/$DEPLOYMENT_NAME -n staging
kubectl describe deployment $DEPLOYMENT_NAME -n staging
```

**Step 2: Common staging issues**

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| Connection timeout | Network/firewall | Verify NSG rules, private endpoints |
| 401/403 errors | Auth misconfiguration | Check App Settings, Key Vault access |
| 500 errors | Application crash | Check application logs |
| Container crash loop | Missing config/dependency | Check container logs, env vars |

**Step 3: Investigate application**

```bash
# Stream App Service logs
az webapp log tail \
  --resource-group $RG \
  --name $APP_NAME

# Get Kubernetes pod logs
kubectl logs -l app=$APP_NAME -n staging --tail=100

# Check application health
curl -v https://$STAGING_URL/health
```

### 3.3 Production Deployment Issues

> **CRITICAL:** Production issues require formal incident management. See [§5 On-Call Procedures](#5-on-call-procedures).

**Immediate Actions:**

1. **DO NOT** attempt multiple retries
2. **DO NOT** make manual changes without approval
3. **Document** everything you observe
4. **Escalate** to on-call lead immediately

**Assessment checklist:**

- [ ] Is the current production version still serving traffic?
- [ ] What percentage of deployment completed?
- [ ] Are there any health check failures?
- [ ] Can we rollback safely?

**See:** [Rollback Procedures](rollback_procedures.md) for detailed rollback steps.

---

## 4. Service Dependency Failures

### 4.1 Database Connectivity

**Symptoms:** Application errors mentioning SQL/database timeouts

**Diagnosis:**

```bash
# Check Azure SQL status
az sql db show \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --query "{status:status,maxSizeBytes:maxSizeBytes,currentUsage:currentServiceObjectiveName}"

# Check connectivity from agent/app
# (Run from App Service console or agent)
sqlcmd -S $SQL_SERVER.database.windows.net -d $DB_NAME -U $USER -P $PASS -Q "SELECT 1"

# Check for blocking queries
az sql db op list \
  --resource-group $RG \
  --server $SQL_SERVER \
  --database $DB_NAME
```

**Resolution:**

| Issue | Action |
|-------|--------|
| Server unavailable | Check Azure status, failover if geo-replicated |
| Connection limit reached | Scale up DTU/vCores, close idle connections |
| Firewall blocking | Add client IP to firewall rules |
| Long-running queries | Identify and kill blocking queries |

### 4.2 Key Vault Access

**Symptoms:** Application fails to start, "Access denied" to secrets

**Diagnosis:**

```bash
# Check Key Vault access policies
az keyvault show \
  --name $KEYVAULT \
  --query "properties.accessPolicies[].{objectId:objectId,permissions:permissions}"

# Check managed identity
az webapp identity show \
  --resource-group $RG \
  --name $APP_NAME

# Test secret access
az keyvault secret show \
  --vault-name $KEYVAULT \
  --name $SECRET_NAME
```

**Resolution:**

```bash
# Grant App Service access to Key Vault
az keyvault set-policy \
  --name $KEYVAULT \
  --object-id $APP_MANAGED_IDENTITY_ID \
  --secret-permissions get list

# If using private endpoint, verify DNS resolution
nslookup $KEYVAULT.vault.azure.net
```

### 4.3 External API Failures

**Symptoms:** Integration failures, timeout errors to third-party services

**Diagnosis:**

```bash
# Test connectivity
curl -v https://$EXTERNAL_API_URL/health

# Check for certificate issues
openssl s_client -connect $EXTERNAL_API_URL:443 -servername $EXTERNAL_API_URL

# Check rate limiting
curl -I https://$EXTERNAL_API_URL/api/endpoint
# Look for: X-RateLimit-Remaining, Retry-After headers
```

**Resolution:**

| Issue | Action |
|-------|--------|
| Certificate expired | Contact vendor, temporary bypass if safe |
| Rate limited | Implement backoff, request limit increase |
| Service down | Activate fallback/circuit breaker, notify stakeholders |
| Network blocked | Check NSG, firewall rules for outbound traffic |

---

## 5. On-Call Procedures

### 5.1 On-Call Schedule

| Week | Primary | Secondary | Escalation |
|------|---------|-----------|------------|
| 1 | Dev Team Lead | Senior Dev 1 | Operations Manager |
| 2 | Senior Dev 1 | Senior Dev 2 | Operations Manager |
| 3 | Senior Dev 2 | Dev Team Lead | Operations Manager |
| 4 | Rotate | Rotate | Operations Manager |

**Shift Times:** 08:00 - 20:00 local (primary), 20:00 - 08:00 (secondary)

### 5.2 Alert Response

**When you receive an alert:**

```
┌───────────────────────────────────────────────────────────┐
│  1. ACKNOWLEDGE within 5 minutes                          │
│     - Respond in #ops-alerts channel                      │
│     - Update PagerDuty/alert system                       │
├───────────────────────────────────────────────────────────┤
│  2. ASSESS severity (5-10 minutes)                        │
│     - Is production impacted?                             │
│     - How many users affected?                            │
│     - Is data at risk?                                    │
├───────────────────────────────────────────────────────────┤
│  3. CLASSIFY incident                                     │
│     - Sev 0: Full outage → Immediate escalation           │
│     - Sev 1: Partial outage → Investigate + escalate      │
│     - Sev 2: Degraded → Investigate, update stakeholders  │
│     - Sev 3: Minor → Document, fix during business hours  │
├───────────────────────────────────────────────────────────┤
│  4. COMMUNICATE                                           │
│     - Update #incidents channel with status               │
│     - Notify stakeholders per severity                    │
└───────────────────────────────────────────────────────────┘
```

### 5.3 Escalation Matrix

| Severity | Response Time | Escalation Time | Notify |
|----------|---------------|-----------------|--------|
| Sev 0 | 5 min | Immediate | CTO, VP Eng, all hands |
| Sev 1 | 15 min | 30 min if unresolved | Engineering Manager |
| Sev 2 | 1 hour | 4 hours if unresolved | Team Lead |
| Sev 3 | Next business day | N/A | Document only |

### 5.4 Handoff Procedure

**End of shift:**

1. Update incident ticket with current status
2. Document any ongoing investigations
3. Brief incoming on-call (call or detailed message)
4. Transfer any active incidents in PagerDuty

**Template:**

```
HANDOFF: [Date] [Time]

Active Incidents:
- INC-1234: Database latency - Monitoring, no action needed
- INC-1235: Build failures - Root cause found, fix in progress

Ongoing Investigations:
- Intermittent 503 errors on /api/users - Logs collected, analyzing

Notes for Next Shift:
- Deploy scheduled for 14:00 tomorrow
- Watch for increased traffic due to marketing campaign
```

---

## 6. Incident War Room

### 6.1 When to Open War Room

- Sev 0: Always
- Sev 1: If not resolved within 30 minutes
- Multiple related incidents
- Customer-impacting issue with unknown cause

### 6.2 War Room Roles

| Role | Responsibility | Who |
|------|----------------|-----|
| Incident Commander | Overall coordination, decisions | On-call lead or manager |
| Technical Lead | Drives investigation, proposes fixes | Senior engineer |
| Communications | Updates stakeholders, status page | Product/Engineering manager |
| Scribe | Documents timeline, actions, decisions | Any available team member |

### 6.3 War Room Conduct

**DO:**
- State your name when joining
- Mute when not speaking
- Use thread/channel for side discussions
- Document everything in incident ticket
- Focus on resolution, not blame

**DON'T:**
- Make changes without announcing
- Pursue multiple theories simultaneously without coordination
- Leave without handoff
- Discuss non-incident topics

### 6.4 Status Update Template

```
INCIDENT UPDATE - [INC-XXXX]
Time: [HH:MM UTC]
Status: Investigating | Identified | Monitoring | Resolved

Impact:
- [Service/feature affected]
- [Number of users/requests affected]
- [Duration so far]

Current Hypothesis:
- [What we think is happening]

Actions Taken:
- [Action 1] - [Result]
- [Action 2] - [Result]

Next Steps:
- [Planned action] - [Owner] - [ETA]

Next Update: [Time]
```

---

## 7. Common Error Reference

### 7.1 Azure DevOps Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `TF400813: Resource not available` | Rate limiting | Wait and retry, reduce parallel jobs |
| `VS30063: Not authorized` | PAT expired or insufficient scope | Regenerate PAT with correct scopes |
| `TF14045: Identity not found` | User removed from org | Re-add user or use different identity |
| `AADSTS70001: Application not found` | Service connection misconfigured | Recreate service connection |

### 7.2 Azure Resource Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `AuthorizationFailed` | RBAC permission missing | Grant required role to identity |
| `ResourceQuotaExceeded` | Subscription limit hit | Request quota increase or delete unused resources |
| `DeploymentFailed` with `Conflict` | Resource locked or in use | Remove lock, wait for other operation |
| `SkuNotAvailable` | SKU not available in region | Use different SKU or region |

### 7.3 Container/Kubernetes Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `ImagePullBackOff` | Cannot pull image | Check registry auth, image exists |
| `CrashLoopBackOff` | Container keeps crashing | Check container logs, fix app |
| `OOMKilled` | Out of memory | Increase memory limits |
| `CreateContainerConfigError` | Bad config (secrets, configmaps) | Verify referenced resources exist |

---

## 8. Log Locations & Analysis

### 8.1 Log Locations

| Component | Location | Access Method |
|-----------|----------|---------------|
| Azure DevOps Pipelines | Pipeline run details | Azure DevOps UI, CLI |
| Azure DevOps Audit | Organization settings → Audit | Export or stream to Log Analytics |
| App Service | Log stream, App Insights | Azure Portal, CLI, Kusto |
| Azure SQL | Query performance insights | Azure Portal |
| Key Vault | Diagnostic logs | Log Analytics |
| Container Apps | Console logs | Azure Portal, CLI |

### 8.2 Log Analytics Queries

**Pipeline failures in last 24 hours:**

```kusto
AzureDevOpsAuditing
| where TimeGenerated > ago(24h)
| where Area == "Pipelines"
| where Details contains "failed"
| project TimeGenerated, ActorDisplayName, Details, IpAddress
| order by TimeGenerated desc
```

**Application errors:**

```kusto
AppExceptions
| where TimeGenerated > ago(1h)
| summarize count() by type, outerMessage
| order by count_ desc
```

**Deployment activity:**

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue contains "deployments"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc
```

### 8.3 Quick Log Commands

```bash
# Stream App Service logs
az webapp log tail -g $RG -n $APP_NAME

# Download pipeline logs
az pipelines logs download --id $BUILD_ID --path ./logs

# Query Application Insights
az monitor app-insights query \
  --app $APP_INSIGHTS_NAME \
  --analytics-query "exceptions | take 10"

# Check Azure activity for failures
az monitor activity-log list \
  --start-time $(date -d '-1 hour' -Iseconds) \
  --status Failed \
  --output table
```

---

## 9. Post-Incident Review

### 9.1 Timeline Requirements

- Sev 0/1: PIR within 48 hours
- Sev 2: PIR within 5 business days
- Sev 3: Document in ticket, no formal PIR required

### 9.2 PIR Template

```markdown
# Post-Incident Review: [INC-XXXX]

## Summary
- **Incident Title:** [Brief description]
- **Severity:** Sev [0-3]
- **Duration:** [Start time] to [End time] ([Total duration])
- **Impact:** [Users affected, transactions failed, revenue impact]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | [First indicator of problem] |
| HH:MM | [Alert triggered] |
| HH:MM | [Investigation started] |
| HH:MM | [Root cause identified] |
| HH:MM | [Mitigation applied] |
| HH:MM | [Full resolution confirmed] |

## Root Cause
[Detailed technical explanation of what caused the incident]

## Contributing Factors
- [Factor 1]
- [Factor 2]

## What Went Well
- [Positive aspect 1]
- [Positive aspect 2]

## What Could Be Improved
- [Area for improvement 1]
- [Area for improvement 2]

## Action Items
| ID | Action | Owner | Due Date | Status |
|----|--------|-------|----------|--------|
| 1 | [Specific action] | [Name] | [Date] | Open |
| 2 | [Specific action] | [Name] | [Date] | Open |

## Lessons Learned
[Key takeaways for preventing similar incidents]
```

### 9.3 PIR Meeting Conduct

**Before the meeting:**
- Incident commander drafts initial timeline
- All participants review timeline independently
- Collect metrics (MTTD, MTTR, impact data)

**During the meeting:**
- Focus on systems, not people (blameless)
- Walk through timeline together
- Identify contributing factors
- Agree on action items with owners

**After the meeting:**
- Publish PIR to wiki/documentation
- Create tickets for action items
- Schedule follow-up for action item review
- Update runbooks if gaps identified
