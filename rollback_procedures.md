# Rollback Procedures — 143it Azure DevOps

> **Related:** [Deployment Strategy](deployment_strategy.md) | [Operational Runbooks](operational_runbooks.md) | [Disaster Recovery](disaster_recovery_plan.md)

This document provides comprehensive rollback procedures for all deployment scenarios. Use these procedures when a deployment causes issues that cannot be quickly hotfixed.

---

## Table of Contents

1. [Rollback Decision Framework](#1-rollback-decision-framework)
2. [Application Rollback](#2-application-rollback)
3. [Database Rollback](#3-database-rollback)
4. [Infrastructure Rollback](#4-infrastructure-rollback)
5. [Feature Flag Rollback](#5-feature-flag-rollback)
6. [Container/Kubernetes Rollback](#6-containerkubernetes-rollback)
7. [Communication During Rollback](#7-communication-during-rollback)
8. [Post-Rollback Actions](#8-post-rollback-actions)

---

## 1. Rollback Decision Framework

### 1.1 When to Rollback vs. Hotfix

```
┌─────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT ISSUE DETECTED                  │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │  Can issue be fixed in    │
              │     < 30 minutes?         │
              └─────────────┬─────────────┘
                   │                │
                  YES              NO
                   │                │
                   ▼                ▼
         ┌─────────────┐    ┌─────────────┐
         │   HOTFIX    │    │  Is data    │
         │  Proceed    │    │  integrity  │
         │  with fix   │    │  at risk?   │
         └─────────────┘    └──────┬──────┘
                              │         │
                             YES       NO
                              │         │
                              ▼         ▼
                    ┌──────────────┐  ┌──────────────┐
                    │  IMMEDIATE   │  │  Is >10% of  │
                    │  ROLLBACK    │  │  users       │
                    │  (< 5 min)   │  │  impacted?   │
                    └──────────────┘  └──────┬───────┘
                                        │         │
                                       YES       NO
                                        │         │
                                        ▼         ▼
                              ┌──────────────┐  ┌──────────────┐
                              │   ROLLBACK   │  │   EVALUATE   │
                              │   within     │  │   Can we     │
                              │   15 min     │  │   fix in     │
                              └──────────────┘  │   1 hour?    │
                                                └──────────────┘
```

### 1.2 Rollback Decision Criteria

| Criterion | Rollback | Hotfix |
|-----------|----------|--------|
| Data corruption occurring | Immediate rollback | Never hotfix |
| Security vulnerability exposed | Immediate rollback | Never hotfix |
| >50% error rate | Rollback | Not recommended |
| 10-50% error rate | Rollback preferred | If fix is <30 min |
| <10% error rate | Consider hotfix | Preferred if <1 hour |
| Performance degradation >2x | Rollback preferred | If fix is obvious |
| Single feature broken | Consider feature flag | Preferred |

### 1.3 Approval Requirements

| Environment | Rollback Approval | Who Can Approve |
|-------------|-------------------|-----------------|
| Development | Self-service | Developer |
| Staging | Team lead notification | Any senior developer |
| Production | Formal approval | On-call lead + Manager |

**Production Rollback Approval Process:**

1. On-call engineer identifies need for rollback
2. Contact on-call lead (phone if after hours)
3. On-call lead confirms rollback decision
4. Document approval in incident channel
5. Execute rollback
6. Notify stakeholders

---

## 2. Application Rollback

### 2.1 Azure App Service Rollback

**Option A: Deployment slot swap (Recommended - Zero downtime)**

```bash
# Swap production back to previous version (staging has old version)
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --target-slot production

# Verify rollback
curl -s https://$APP_URL/health | jq .
curl -s https://$APP_URL/version | jq .
```

**Option B: Redeploy previous artifact**

```bash
# List recent deployments
az webapp deployment list-publishing-credentials \
  --resource-group $RG \
  --name $APP_NAME

# Find previous successful build
az pipelines runs list \
  --org https://dev.azure.com/143it \
  --project Head_Office \
  --pipeline-ids $PIPELINE_ID \
  --result succeeded \
  --top 5

# Redeploy specific artifact
az pipelines run \
  --org https://dev.azure.com/143it \
  --project Head_Office \
  --id $RELEASE_PIPELINE_ID \
  --variables "artifactVersion=$PREVIOUS_VERSION"
```

**Option C: Restore from backup (Last resort)**

```bash
# List available backups
az webapp config backup list \
  --resource-group $RG \
  --webapp-name $APP_NAME

# Restore specific backup
az webapp config backup restore \
  --resource-group $RG \
  --webapp-name $APP_NAME \
  --backup-name $BACKUP_NAME \
  --overwrite
```

### 2.2 Azure Functions Rollback

```bash
# List deployment history
func azure functionapp list-functions $FUNCTION_APP_NAME

# Redeploy previous package
az functionapp deployment source config-zip \
  --resource-group $RG \
  --name $FUNCTION_APP_NAME \
  --src $PREVIOUS_PACKAGE_PATH

# Or use deployment slots
az functionapp deployment slot swap \
  --resource-group $RG \
  --name $FUNCTION_APP_NAME \
  --slot staging
```

### 2.3 Rollback Verification Checklist

After rollback, verify:

- [ ] Application health endpoint returns 200
- [ ] Version endpoint shows expected previous version
- [ ] Key user flows work (login, main features)
- [ ] Error rate returned to baseline
- [ ] No new errors in Application Insights
- [ ] External integrations functional

---

## 3. Database Rollback

### 3.1 Schema Migration Rollback

> **WARNING:** Database rollbacks can cause data loss. Always assess data impact before proceeding.

**Pre-requisites:**
- All migrations must have corresponding DOWN migrations
- Test rollback procedure in staging first
- Take backup before rollback

**Using Entity Framework:**

```bash
# List applied migrations
dotnet ef migrations list --project $PROJECT

# Rollback to specific migration
dotnet ef database update $PREVIOUS_MIGRATION_NAME --project $PROJECT

# Generate rollback script (for review)
dotnet ef migrations script $CURRENT_MIGRATION $PREVIOUS_MIGRATION --project $PROJECT
```

**Using Flyway:**

```bash
# Show migration history
flyway info

# Undo last migration (requires Flyway Teams)
flyway undo

# Or clean and re-migrate to specific version (DESTRUCTIVE - staging only)
flyway clean
flyway migrate -target=$VERSION
```

**Manual SQL Rollback:**

```sql
-- Always run in transaction
BEGIN TRANSACTION;

-- Example: Rollback column addition
ALTER TABLE Users DROP COLUMN NewColumn;

-- Example: Rollback table creation
DROP TABLE IF EXISTS NewTable;

-- Example: Restore dropped column from backup
ALTER TABLE Users ADD OldColumn VARCHAR(255);
UPDATE Users u
SET OldColumn = b.OldColumn
FROM UsersBackup b
WHERE u.Id = b.Id;

-- Verify before committing
SELECT COUNT(*) FROM Users WHERE OldColumn IS NULL; -- Should be 0

COMMIT;
-- Or ROLLBACK; if verification fails
```

### 3.2 Data Rollback Scenarios

**Scenario A: Bad data written by new code**

```sql
-- Identify affected records
SELECT * FROM Orders
WHERE CreatedAt > @DeploymentTime
  AND Status = 'Invalid';

-- Option 1: Fix in place
UPDATE Orders
SET Status = 'Pending', ProcessedBy = NULL
WHERE CreatedAt > @DeploymentTime
  AND Status = 'Invalid';

-- Option 2: Soft delete and recreate
UPDATE Orders
SET IsDeleted = 1, DeletedReason = 'Rollback INC-1234'
WHERE CreatedAt > @DeploymentTime
  AND Status = 'Invalid';
```

**Scenario B: Data migration went wrong**

```sql
-- Restore from backup table (created before migration)
INSERT INTO Users (Id, Email, Name, LegacyField)
SELECT Id, Email, Name, LegacyField
FROM Users_Backup_20240115
WHERE Id NOT IN (SELECT Id FROM Users);

-- Restore overwritten values
UPDATE Users u
SET LegacyField = b.LegacyField
FROM Users_Backup_20240115 b
WHERE u.Id = b.Id
  AND u.LegacyField IS NULL;
```

### 3.3 Point-in-Time Restore

**Azure SQL:**

```bash
# Restore to point in time before deployment
az sql db restore \
  --resource-group $RG \
  --server $SQL_SERVER \
  --name $DB_NAME \
  --dest-name "${DB_NAME}-restored" \
  --time "2024-01-15T10:00:00Z"

# Verify restored database
sqlcmd -S $SQL_SERVER.database.windows.net \
  -d "${DB_NAME}-restored" \
  -U $ADMIN \
  -P $PASSWORD \
  -Q "SELECT COUNT(*) FROM Users"

# Swap databases (requires application downtime)
# 1. Stop application
# 2. Rename current to backup
# 3. Rename restored to production name
# 4. Start application
```

### 3.4 Data Rollback Decision Matrix

| Scenario | Data Loss Risk | Recommended Approach |
|----------|----------------|----------------------|
| Schema change only | None | Migration rollback |
| New data created | Medium | Soft delete + audit |
| Existing data modified | High | Point-in-time restore |
| Data corruption | Critical | Point-in-time restore |
| Foreign key violations | Medium | Fix referential integrity first |

---

## 4. Infrastructure Rollback

### 4.1 Terraform Rollback

```bash
# Show current state
terraform show

# View state history (if using remote backend)
terraform state list

# Rollback to previous state version (Terraform Cloud/Enterprise)
# Via UI: Workspace → States → Select previous → "Rollback to this state"

# Manual rollback: Apply previous configuration
git checkout $PREVIOUS_COMMIT -- *.tf
terraform plan -out=rollback.plan
terraform apply rollback.plan
```

### 4.2 Bicep/ARM Rollback

```bash
# List deployment history
az deployment group list \
  --resource-group $RG \
  --query "[].{name:name,timestamp:properties.timestamp,status:properties.provisioningState}" \
  --output table

# Redeploy previous template
az deployment group create \
  --resource-group $RG \
  --template-file ./previous-version/main.bicep \
  --parameters ./previous-version/parameters.json
```

### 4.3 App Configuration Rollback

```bash
# List configuration history
az appconfig revision list \
  --name $APP_CONFIG_NAME \
  --key $CONFIG_KEY \
  --top 10

# Restore previous value
az appconfig kv set \
  --name $APP_CONFIG_NAME \
  --key $CONFIG_KEY \
  --value "$PREVIOUS_VALUE"
```

---

## 5. Feature Flag Rollback

### 5.1 Azure App Configuration Feature Flags

**Disable feature immediately:**

```bash
# Disable feature flag
az appconfig feature disable \
  --name $APP_CONFIG_NAME \
  --feature $FEATURE_NAME

# Verify
az appconfig feature show \
  --name $APP_CONFIG_NAME \
  --feature $FEATURE_NAME
```

**Percentage rollback (gradual):**

```bash
# Reduce percentage to 0
az appconfig feature filter update \
  --name $APP_CONFIG_NAME \
  --feature $FEATURE_NAME \
  --filter-name "Percentage" \
  --filter-parameters "Value=0"
```

### 5.2 LaunchDarkly Feature Flags

```bash
# Turn off flag via API
curl -X PATCH \
  "https://app.launchdarkly.com/api/v2/flags/$PROJECT_KEY/$FLAG_KEY" \
  -H "Authorization: $LD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[{"op": "replace", "path": "/environments/production/on", "value": false}]'
```

### 5.3 Feature Flag Rollback Checklist

- [ ] Identify all flags changed in deployment
- [ ] Disable new feature flags first
- [ ] Revert configuration changes to existing flags
- [ ] Clear any caching (application, CDN)
- [ ] Verify feature is no longer accessible
- [ ] Monitor for users still seeing old behavior

---

## 6. Container/Kubernetes Rollback

### 6.1 Kubernetes Deployment Rollback

```bash
# View rollout history
kubectl rollout history deployment/$DEPLOYMENT_NAME -n $NAMESPACE

# Rollback to previous revision
kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE

# Rollback to specific revision
kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE --to-revision=$REVISION

# Verify rollback
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE
kubectl get pods -n $NAMESPACE -l app=$APP_NAME
```

### 6.2 Helm Release Rollback

```bash
# View release history
helm history $RELEASE_NAME -n $NAMESPACE

# Rollback to previous release
helm rollback $RELEASE_NAME -n $NAMESPACE

# Rollback to specific revision
helm rollback $RELEASE_NAME $REVISION -n $NAMESPACE

# Verify
helm status $RELEASE_NAME -n $NAMESPACE
```

### 6.3 Azure Container Apps Rollback

```bash
# List revisions
az containerapp revision list \
  --name $CONTAINER_APP_NAME \
  --resource-group $RG \
  --query "[].{name:name,active:properties.active,trafficWeight:properties.trafficWeight}"

# Activate previous revision
az containerapp revision activate \
  --name $CONTAINER_APP_NAME \
  --resource-group $RG \
  --revision $PREVIOUS_REVISION_NAME

# Shift traffic to previous revision
az containerapp ingress traffic set \
  --name $CONTAINER_APP_NAME \
  --resource-group $RG \
  --revision-weight "$PREVIOUS_REVISION_NAME=100"

# Deactivate failed revision
az containerapp revision deactivate \
  --name $CONTAINER_APP_NAME \
  --resource-group $RG \
  --revision $FAILED_REVISION_NAME
```

### 6.4 Container Image Rollback

```bash
# Find previous image tag
az acr repository show-tags \
  --name $ACR_NAME \
  --repository $IMAGE_NAME \
  --top 10 \
  --orderby time_desc

# Update deployment to use previous image
kubectl set image deployment/$DEPLOYMENT_NAME \
  $CONTAINER_NAME=$ACR_NAME.azurecr.io/$IMAGE_NAME:$PREVIOUS_TAG \
  -n $NAMESPACE

# Or edit deployment directly
kubectl edit deployment/$DEPLOYMENT_NAME -n $NAMESPACE
```

---

## 7. Communication During Rollback

### 7.1 Internal Communication Template

**Slack/Teams Message (Start):**

```
🔄 ROLLBACK IN PROGRESS - [Environment]

Incident: INC-XXXX
Issue: [Brief description]
Impact: [Users/services affected]
Action: Rolling back to version [X.X.X]
ETA: [X minutes]

Updates will be posted here.
```

**Slack/Teams Message (Complete):**

```
✅ ROLLBACK COMPLETE - [Environment]

Incident: INC-XXXX
Duration: [X minutes]
Current Version: [X.X.X]
Status: Monitoring

Next Steps:
- Root cause analysis in progress
- Fix will be deployed once validated

PIR scheduled for [Date/Time]
```

### 7.2 External Communication (Status Page)

**Investigating:**
```
We are investigating reports of [issue description].
Some users may experience [specific symptoms].
We are working to resolve this as quickly as possible.
```

**Identified:**
```
We have identified the cause of [issue].
We are rolling back the recent deployment to restore service.
Expected resolution: [ETA]
```

**Resolved:**
```
The rollback is complete and service has been restored.
All systems are operating normally.
We apologize for any inconvenience.
A full post-incident report will be published within 48 hours.
```

### 7.3 Stakeholder Notification Matrix

| Stakeholder | Sev 0 | Sev 1 | Sev 2 | Method |
|-------------|-------|-------|-------|--------|
| CTO | Immediate | 15 min | Summary | Phone/SMS |
| VP Engineering | Immediate | 15 min | Summary | Slack/Phone |
| Product Manager | 15 min | 30 min | Summary | Slack |
| Customer Success | 15 min | 30 min | Summary | Email |
| Support Team | 5 min | 15 min | 30 min | Slack |
| Development Team | 5 min | 15 min | Summary | Slack |

---

## 8. Post-Rollback Actions

### 8.1 Immediate Actions (Within 1 hour)

- [ ] Verify all services are healthy
- [ ] Confirm error rates returned to baseline
- [ ] Check no data was lost or corrupted
- [ ] Update incident ticket with rollback details
- [ ] Notify stakeholders of resolution
- [ ] Update status page

### 8.2 Short-term Actions (Within 24 hours)

- [ ] Conduct preliminary root cause analysis
- [ ] Document exact steps taken during rollback
- [ ] Identify what tests/checks were missing
- [ ] Block re-deployment until fix verified
- [ ] Schedule Post-Incident Review

### 8.3 Root Cause Categories

When documenting the incident, classify the root cause:

| Category | Examples | Prevention |
|----------|----------|------------|
| Code defect | Logic error, null reference | Better testing |
| Configuration | Wrong environment vars | Config validation |
| Infrastructure | Resource exhaustion | Capacity planning |
| External | Third-party API failure | Circuit breakers |
| Process | Skipped approval | Enforce gates |
| Data | Bad migration | Rollback testing |

### 8.4 Rollback Metrics to Track

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Time to Detection (TTD) | < 5 min | Alert time - deploy time |
| Time to Decide (TTDec) | < 10 min | Decision time - detection time |
| Time to Rollback (TTR) | < 15 min | Completion time - decision time |
| Total Recovery Time | < 30 min | Completion time - deploy time |
| Rollback Success Rate | 100% | Successful / attempted |

### 8.5 Rollback Runbook Review

After each rollback, answer:

1. Was the rollback procedure followed correctly?
2. Were there any steps that were unclear or missing?
3. Did we have the right access and permissions?
4. Were the right people notified at the right times?
5. What could have prevented the need for rollback?

Update this document with any improvements identified.
