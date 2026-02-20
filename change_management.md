# Change Management — 143it Azure DevOps

> **Related:** [Deployment Strategy](deployment_strategy.md) | [Rollback Procedures](rollback_procedures.md) | [Security Baseline](security_baseline.md)

This document defines the formal change management process for all changes to the 143it DevOps environment, including code deployments, infrastructure changes, and configuration updates.

---

## Table of Contents

1. [Change Classification](#1-change-classification)
2. [Change Advisory Board (CAB)](#2-change-advisory-board-cab)
3. [Change Request Process](#3-change-request-process)
4. [Approval Workflows](#4-approval-workflows)
5. [Change Windows & Blackouts](#5-change-windows--blackouts)
6. [Emergency Changes](#6-emergency-changes)
7. [Change Communication](#7-change-communication)
8. [Change Success Criteria](#8-change-success-criteria)
9. [Post-Implementation Review](#9-post-implementation-review)

---

## 1. Change Classification

### 1.1 Change Types

| Type | Definition | Examples | Approval |
|------|------------|----------|----------|
| **Standard** | Pre-approved, low-risk, routine | Dependency updates, minor bug fixes, config changes within approved parameters | Auto-approved |
| **Normal** | Requires assessment, moderate risk | New features, schema changes, infrastructure scaling | CAB approval |
| **Emergency** | Urgent fix for critical issue | Security patches, production outages, data corruption fixes | On-call Lead + Post-CAB review |

### 1.2 Risk Assessment Matrix

| Impact ↓ / Likelihood → | Low | Medium | High |
|-------------------------|-----|--------|------|
| **High** (Production outage possible) | Normal | Normal | CAB + Security |
| **Medium** (Service degradation possible) | Standard | Normal | Normal |
| **Low** (Minimal user impact) | Standard | Standard | Normal |

### 1.3 Impact Categories

| Level | Definition | Examples |
|-------|------------|----------|
| **Critical** | Full production outage | Database failure, auth system down |
| **High** | Major feature unavailable | Payment processing, user registration |
| **Medium** | Partial functionality affected | Reporting delayed, non-critical API slow |
| **Low** | Minimal/no user impact | Admin tools, internal dashboards |

---

## 2. Change Advisory Board (CAB)

### 2.1 CAB Composition

| Role | Responsibility | Required for |
|------|----------------|--------------|
| **CAB Chair** (Engineering Manager) | Final approval authority, meeting facilitation | All CAB meetings |
| **Development Lead** | Technical feasibility, code quality | All changes |
| **QA Lead** | Test coverage, quality sign-off | All changes |
| **Operations Lead** | Infrastructure impact, deployment readiness | All changes |
| **Security Representative** | Security implications | Security-related changes |
| **Product Manager** | Business justification | Feature changes |

### 2.2 CAB Meeting Schedule

| Meeting | Frequency | Time | Purpose |
|---------|-----------|------|---------|
| **Weekly CAB** | Tuesday 10:00 AM | 1 hour | Review and approve Normal changes |
| **Emergency CAB** | As needed | 30 min | Approve Emergency changes |
| **Change Review** | Friday 3:00 PM | 30 min | Review week's changes, lessons learned |

### 2.3 CAB Decision Criteria

**Approve if:**
- [ ] Change is fully documented
- [ ] Risk assessment completed
- [ ] Test evidence provided
- [ ] Rollback plan documented
- [ ] Communication plan in place
- [ ] Deployment window confirmed
- [ ] On-call coverage arranged

**Reject if:**
- [ ] Missing documentation
- [ ] Inadequate testing
- [ ] No rollback plan
- [ ] Conflicts with blackout period
- [ ] Resource constraints
- [ ] Unresolved dependencies

---

## 3. Change Request Process

### 3.1 Change Request Form

```markdown
# Change Request: [CR-XXXX]

## Summary
**Title:** [Brief description]
**Requester:** [Name]
**Date Submitted:** [YYYY-MM-DD]
**Requested Implementation Date:** [YYYY-MM-DD]

## Classification
**Type:** [ ] Standard  [ ] Normal  [ ] Emergency
**Risk Level:** [ ] Low  [ ] Medium  [ ] High
**Impact Level:** [ ] Low  [ ] Medium  [ ] High  [ ] Critical

## Change Details
**Description:**
[Detailed description of the change]

**Business Justification:**
[Why is this change needed? What problem does it solve?]

**Scope:**
- [ ] Code change
- [ ] Database change
- [ ] Infrastructure change
- [ ] Configuration change
- [ ] Security change

**Affected Systems:**
- [System 1]
- [System 2]

**Dependencies:**
- [Dependency 1]
- [Dependency 2]

## Implementation Plan
**Pre-Implementation Steps:**
1. [Step 1]
2. [Step 2]

**Implementation Steps:**
1. [Step 1]
2. [Step 2]

**Post-Implementation Steps:**
1. [Step 1]
2. [Step 2]

**Estimated Duration:** [X hours/minutes]

## Test Evidence
**Test Types Completed:**
- [ ] Unit tests (Coverage: XX%)
- [ ] Integration tests
- [ ] E2E tests
- [ ] Performance tests
- [ ] Security scan

**Staging Validation:**
- [ ] Deployed to staging
- [ ] QA sign-off obtained
- [ ] Soak time completed (X hours)

## Rollback Plan
**Rollback Trigger:**
[When will rollback be initiated?]

**Rollback Steps:**
1. [Step 1]
2. [Step 2]

**Estimated Rollback Time:** [X minutes]

**Rollback Tested:** [ ] Yes  [ ] No

## Communication Plan
**Stakeholders to Notify:**
- [Stakeholder 1]: [Method]
- [Stakeholder 2]: [Method]

**User Communication Required:** [ ] Yes  [ ] No
**Status Page Update Required:** [ ] Yes  [ ] No

## Approvals
| Role | Name | Decision | Date |
|------|------|----------|------|
| Development Lead | | | |
| QA Lead | | | |
| Operations Lead | | | |
| CAB Chair | | | |
```

### 3.2 Change Request Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    CHANGE SUBMITTED                         │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │     Is it Standard?       │
              └─────────────┬─────────────┘
                   │                │
                  YES              NO
                   │                │
                   ▼                ▼
         ┌─────────────┐    ┌─────────────┐
         │ Auto-approve│    │ Submit to   │
         │ Proceed     │    │ CAB queue   │
         └─────────────┘    └──────┬──────┘
                                   │
                           ┌───────┴───────┐
                           │  CAB Review   │
                           └───────┬───────┘
                      ┌────────────┼────────────┐
                      ▼            ▼            ▼
               ┌──────────┐ ┌──────────┐ ┌──────────┐
               │ APPROVED │ │ DEFERRED │ │ REJECTED │
               └────┬─────┘ └────┬─────┘ └────┬─────┘
                    │            │            │
                    ▼            ▼            ▼
               Schedule     Resubmit      Document
               change       with fixes    reasons
```

### 3.3 Lead Times

| Change Type | Minimum Lead Time | Submission Deadline |
|-------------|-------------------|---------------------|
| Standard | 1 business day | N/A (auto-approved) |
| Normal | 3 business days | Monday 5 PM for Tuesday CAB |
| Normal (Complex) | 5 business days | Monday 5 PM for Tuesday CAB |
| Emergency | 0 | Immediate (follow emergency process) |

---

## 4. Approval Workflows

### 4.1 Standard Change Approval

**Pre-approved changes (no CAB required):**

| Change Category | Conditions |
|-----------------|------------|
| Dependency updates | No breaking changes, all tests pass |
| Minor bug fixes | Isolated change, no schema changes |
| Documentation updates | No code changes |
| Config parameter adjustments | Within approved ranges |
| Scaling (within limits) | Auto-scaling rules, no manual intervention |

**Approval in Azure DevOps:**

```yaml
# Pipeline approval for standard changes
- stage: DeployProduction
  condition: |
    and(
      eq(variables['changeType'], 'standard'),
      succeeded('AllTests')
    )
  # No manual approval required for standard changes
```

### 4.2 Normal Change Approval

**Required approvers:**

| Environment | Required Approvers | Minimum |
|-------------|-------------------|---------|
| Development | None | 0 |
| Staging | QA Lead | 1 |
| Production | CAB (Dev Lead + QA Lead + Ops Lead) | 3 |

**Approval in Azure DevOps:**

```yaml
# Environment with approval gates
environments:
  - name: production
    approvals:
      - type: scheduled
        parameters:
          scheduledDeploymentDate: $(deploymentDate)
      - type: approval
        parameters:
          approvers:
            - devops-cab@143it.com
          minimumRequiredApprovers: 3
          timeout: 24h
          instructions: |
            Review CR-$(changeRequestId) before approving.
            Checklist:
            - [ ] Risk assessment reviewed
            - [ ] Rollback plan confirmed
            - [ ] On-call notified
```

### 4.3 Emergency Change Approval

**Expedited approval process:**

```
┌─────────────────────────────────────────────────────────────┐
│                  EMERGENCY IDENTIFIED                       │
│          (Security vulnerability, outage, data loss)        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              On-Call Lead Approval (Required)               │
│                    Phone/Slack/Teams                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Engineering Manager Notification               │
│                    (Informational)                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    IMPLEMENT CHANGE                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         Post-Implementation CAB Review (48 hours)           │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Change Windows & Blackouts

### 5.1 Standard Change Windows

| Day | Time (UTC) | Time (EST) | Change Types |
|-----|------------|------------|--------------|
| Tuesday | 14:00 - 18:00 | 09:00 - 13:00 | All |
| Thursday | 14:00 - 18:00 | 09:00 - 13:00 | All |
| Saturday | 10:00 - 14:00 | 05:00 - 09:00 | Maintenance only |

### 5.2 Blackout Periods

| Period | Dates | Scope | Exceptions |
|--------|-------|-------|------------|
| Month-end Close | Last 3 business days | All changes | Emergency only |
| Quarter-end | Last week of Q | All changes | Emergency only |
| Holiday Freeze | Dec 15 - Jan 5 | All changes | Emergency only |
| Major Releases | 48 hours post-release | Related systems | Emergency only |

### 5.3 Blackout Calendar

```
# Managed in Azure DevOps Wiki or shared calendar

## 2024 Blackout Periods

| Month | Blackout Dates | Reason |
|-------|----------------|--------|
| March | Mar 27-31 | Q1 Close |
| April | Apr 15 | Tax Day |
| June | Jun 26-30 | Q2 Close |
| July | Jul 4 | Holiday |
| September | Sep 25-30 | Q3 Close |
| November | Nov 28-29 | Thanksgiving |
| December | Dec 15 - Jan 5 | Holiday Freeze |
```

---

## 6. Emergency Changes

### 6.1 Emergency Criteria

A change qualifies as Emergency if:

- [ ] Active security vulnerability being exploited
- [ ] Production outage affecting >10% of users
- [ ] Data loss or corruption occurring
- [ ] Regulatory/compliance deadline at risk
- [ ] Revenue-impacting issue (>$X/hour loss)

### 6.2 Emergency Process

**Step 1: Declare Emergency**

```
WHO: On-call engineer or Engineering Manager
HOW: Post in #incidents channel:

🚨 EMERGENCY CHANGE DECLARED 🚨
Issue: [Brief description]
Impact: [Users/systems affected]
Proposed Fix: [What will be changed]
Requester: [Name]
Approver Needed: @on-call-lead
```

**Step 2: Get Approval**

| Approver | Contact Method | Response SLA |
|----------|----------------|--------------|
| On-call Lead | Phone → Slack | 5 minutes |
| Engineering Manager | Phone → Slack | 15 minutes |
| VP Engineering (if On-call unavailable) | Phone | 15 minutes |

**Step 3: Implement with Minimal Scope**

- Only fix the immediate issue
- No additional "while we're at it" changes
- Document all changes in real-time

**Step 4: Post-Implementation**

- [ ] Verify fix is working
- [ ] Monitor for 30 minutes minimum
- [ ] Create post-CAB change request within 24 hours
- [ ] Schedule PIR within 48 hours

### 6.3 Emergency Pipeline

```yaml
# emergency-deploy.yml
parameters:
- name: emergencyApprover
  type: string
- name: incidentId
  type: string

trigger: none  # Manual only

stages:
- stage: EmergencyValidation
  jobs:
  - job: ValidateEmergency
    steps:
    - task: Bash@3
      displayName: 'Log emergency deployment'
      inputs:
        targetType: 'inline'
        script: |
          echo "Emergency deployment initiated"
          echo "Incident: ${{ parameters.incidentId }}"
          echo "Approver: ${{ parameters.emergencyApprover }}"
          echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

          # Log to audit system
          curl -X POST "$AUDIT_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d '{
              "type": "emergency_change",
              "incident": "${{ parameters.incidentId }}",
              "approver": "${{ parameters.emergencyApprover }}",
              "deployer": "$(Build.RequestedFor)"
            }'

- stage: SmokeTestsOnly
  jobs:
  - job: MinimalTests
    steps:
    - task: Bash@3
      displayName: 'Run smoke tests only'
      inputs:
        targetType: 'inline'
        script: npm run test:smoke

- stage: DeployProduction
  jobs:
  - deployment: EmergencyDeploy
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - template: steps/deploy-app.yml
```

---

## 7. Change Communication

### 7.1 Communication Matrix

| Audience | Standard | Normal | Emergency |
|----------|----------|--------|-----------|
| Development Team | Slack | Slack + Email | Slack (immediate) |
| QA Team | Slack | Slack + Email | Slack (immediate) |
| Operations | Slack | Slack + Email + Calendar | Phone + Slack |
| Product | None | Email | Email (post-fix) |
| Support | None | Email (if user-facing) | Email + Slack |
| Executives | None | Weekly summary | Email (Sev 0/1 only) |
| Customers | None | Status page (if impactful) | Status page |

### 7.2 Pre-Change Notification

**Template (Slack/Teams):**

```
📋 SCHEDULED CHANGE NOTIFICATION

CR: CR-2024-0123
Type: Normal
Window: Tuesday 14:00-18:00 UTC

Summary:
[Brief description of change]

Impact:
- Expected: [What users might notice]
- Downtime: [None / X minutes]

Rollback Plan:
[Brief rollback summary]

Contacts:
- Implementer: @engineer
- On-call: @on-call-lead

React with ✅ to acknowledge.
```

### 7.3 Post-Change Notification

**Template (Success):**

```
✅ CHANGE COMPLETED SUCCESSFULLY

CR: CR-2024-0123
Completed: [Timestamp]
Duration: [X minutes]

Validation:
- Health checks: PASS
- Smoke tests: PASS
- Error rate: Normal

No further action required.
```

**Template (Rollback):**

```
⚠️ CHANGE ROLLED BACK

CR: CR-2024-0123
Rolled Back: [Timestamp]
Reason: [Brief reason]

Current Status:
- System restored to previous version
- All services operational

Next Steps:
- PIR scheduled for [Date/Time]
- Fix will be resubmitted after review
```

---

## 8. Change Success Criteria

### 8.1 Validation Checklist

**Immediate (0-5 minutes):**

- [ ] Deployment completed without errors
- [ ] Application health check passing
- [ ] No new errors in logs

**Short-term (5-30 minutes):**

- [ ] Smoke tests passing
- [ ] Error rate at or below baseline
- [ ] Response times at or below baseline
- [ ] No user complaints

**Extended (30-60 minutes):**

- [ ] All automated monitors green
- [ ] Business metrics normal
- [ ] No degradation observed

### 8.2 Success/Failure Determination

| Metric | Success | Warning | Failure |
|--------|---------|---------|---------|
| Error rate | ≤ baseline | baseline + 1% | > baseline + 2% |
| p95 latency | ≤ baseline | baseline + 20% | > baseline + 50% |
| Availability | 100% | 99.9% | < 99.9% |
| User complaints | 0 | 1-2 | > 2 |

### 8.3 Rollback Decision

**Automatic rollback if:**
- Health check fails for 3 consecutive minutes
- Error rate exceeds 5% for 2 minutes
- Availability drops below 99%

**Manual rollback decision if:**
- Performance degradation observed
- Partial feature failures
- Edge case issues reported

---

## 9. Post-Implementation Review

### 9.1 Review Requirements

| Change Type | PIR Required | Timeline |
|-------------|--------------|----------|
| Standard | No | N/A |
| Normal (successful) | Brief summary | 24 hours |
| Normal (rolled back) | Full PIR | 48 hours |
| Emergency | Full PIR | 48 hours |

### 9.2 PIR Template

```markdown
# Post-Implementation Review: CR-XXXX

## Change Summary
- **Title:** [Change title]
- **Type:** [Standard/Normal/Emergency]
- **Implementation Date:** [Date/Time]
- **Implementer:** [Name]

## Outcome
- **Status:** [ ] Successful  [ ] Rolled Back  [ ] Partial Success
- **Duration:** [Planned vs Actual]
- **Downtime:** [Planned vs Actual]

## What Went Well
- [Positive aspect 1]
- [Positive aspect 2]

## What Could Be Improved
- [Area for improvement 1]
- [Area for improvement 2]

## Issues Encountered
| Issue | Impact | Resolution |
|-------|--------|------------|
| [Issue 1] | [Impact] | [How resolved] |

## Action Items
| Action | Owner | Due Date |
|--------|-------|----------|
| [Action 1] | [Name] | [Date] |

## Metrics
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Error rate | X% | X% | ≤X% |
| p95 latency | Xms | Xms | ≤Xms |

## Lessons Learned
[Key takeaways for future changes]

## Sign-off
| Role | Name | Date |
|------|------|------|
| Implementer | | |
| CAB Chair | | |
```

### 9.3 Continuous Improvement

**Monthly Change Metrics Review:**

| Metric | Target | Track |
|--------|--------|-------|
| Change success rate | > 95% | % of changes without rollback |
| Emergency change rate | < 5% | % of changes classified as emergency |
| CAB approval time | < 48 hours | Average time from submission to approval |
| Change lead time | Decreasing | Submission to implementation |
| Rollback frequency | Decreasing | Number of rollbacks per month |

**Quarterly Process Improvements:**

- Review failed/rolled back changes for patterns
- Update Standard change catalog
- Refine risk assessment criteria
- Update blackout calendar
- Train new CAB members
