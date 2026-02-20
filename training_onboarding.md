# Training & Onboarding — 143it Azure DevOps

> **Related:** [Security Baseline](security_baseline.md) | [Operational Runbooks](operational_runbooks.md) | [Implementation Checklist](implementation_checklist.md)

This document provides the training curriculum and onboarding procedures for team members joining the 143it DevOps environment.

---

## Table of Contents

1. [Onboarding Overview](#1-onboarding-overview)
2. [Role-Based Training Paths](#2-role-based-training-paths)
3. [Developer Onboarding](#3-developer-onboarding)
4. [QA Engineer Onboarding](#4-qa-engineer-onboarding)
5. [Operations Engineer Onboarding](#5-operations-engineer-onboarding)
6. [DevOps Champion Program](#6-devops-champion-program)
7. [Competency Assessment](#7-competency-assessment)
8. [Ongoing Training](#8-ongoing-training)

---

## 1. Onboarding Overview

### 1.1 Onboarding Timeline

| Day | Focus | Outcome |
|-----|-------|---------|
| **Day 1** | Environment setup, accounts | Access to all required systems |
| **Day 2-3** | Core tools training | Navigate Azure DevOps confidently |
| **Day 4-5** | Team processes | Understand workflows and conventions |
| **Week 2** | Hands-on practice | Complete first guided contribution |
| **Week 3-4** | Independent work | Full productivity with support |
| **30 days** | Assessment | Verify competency, address gaps |

### 1.2 Onboarding Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to first PR | ≤ 5 days | Date of first PR merged |
| Time to independent contribution | ≤ 2 weeks | First unassisted feature |
| Onboarding satisfaction | ≥ 4/5 | Survey score |
| Competency assessment pass | 100% | Assessment results |

### 1.3 Onboarding Checklist (All Roles)

```markdown
## Day 1 Checklist

### Account Setup
- [ ] Azure AD account created (IT)
- [ ] MFA configured
- [ ] Added to Azure DevOps organization
- [ ] Added to appropriate Azure AD security groups
- [ ] GitHub account linked (if applicable)
- [ ] Email/Teams access confirmed

### Development Environment
- [ ] Laptop configured with approved image
- [ ] IDE installed and configured (VS Code/Visual Studio)
- [ ] Git installed and configured
- [ ] Azure CLI installed
- [ ] Required SDKs installed (.NET, Node.js, etc.)

### Documentation Access
- [ ] Azure DevOps Wiki access confirmed
- [ ] Documentation repository cloned
- [ ] start.md reviewed
- [ ] Team processes overview completed

### Meeting Introductions
- [ ] Meet with manager
- [ ] Meet with team lead
- [ ] Meet with buddy/mentor
- [ ] Team standup introduction
```

---

## 2. Role-Based Training Paths

### 2.1 Training Path Overview

```
                    ┌─────────────────────┐
                    │    ALL ROLES        │
                    │    Core Training    │
                    │    (Days 1-3)       │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   DEVELOPER   │    │  QA ENGINEER  │    │  OPERATIONS   │
│   Path        │    │  Path         │    │  Path         │
│   (Days 4-10) │    │  (Days 4-10)  │    │  (Days 4-10)  │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 2.2 Core Training (All Roles)

| Module | Duration | Content |
|--------|----------|---------|
| Azure DevOps Navigation | 2 hours | Organization structure, projects, navigation |
| Work Item Basics | 1 hour | Creating, updating, linking work items |
| Git Fundamentals | 2 hours | Branching, committing, PRs |
| Security & Compliance | 1 hour | Security policies, MFA, secrets handling |
| Team Communication | 1 hour | Teams channels, escalation paths |

---

## 3. Developer Onboarding

### 3.1 Developer Training Schedule

**Week 1:**

| Day | Morning (9-12) | Afternoon (1-5) |
|-----|----------------|-----------------|
| Mon | Environment setup | Core training: Azure DevOps |
| Tue | Core training: Git | Core training: Security |
| Wed | Repository walkthrough | Codebase overview |
| Thu | Pipeline training | First PR (guided) |
| Fri | Code review training | Pair programming |

**Week 2:**

| Day | Focus |
|-----|-------|
| Mon-Tue | Feature development (with buddy) |
| Wed | Debugging and troubleshooting |
| Thu | Testing practices |
| Fri | Independent work begins |

### 3.2 Developer Environment Setup

**Required Tools:**

```bash
# Install via winget (Windows) or brew (macOS)

# Git
winget install Git.Git
# or
brew install git

# Azure CLI
winget install Microsoft.AzureCLI
# or
brew install azure-cli

# VS Code
winget install Microsoft.VisualStudioCode

# Required VS Code extensions
code --install-extension ms-vscode.azure-repos
code --install-extension ms-azure-devops.azure-pipelines
code --install-extension eamodio.gitlens
code --install-extension ms-dotnettools.csharp
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
```

**Git Configuration:**

```bash
# Set identity
git config --global user.name "Your Name"
git config --global user.email "your.email@143it.com"

# Set default branch
git config --global init.defaultBranch main

# Set credential helper
git config --global credential.helper manager

# Configure PR workflow
git config --global push.autoSetupRemote true
```

### 3.3 Repository Guidelines

**Cloning the Repository:**

```bash
# Clone via Azure DevOps CLI
az repos clone --repository Head_Office --org https://dev.azure.com/143it

# Or via Git
git clone https://143it@dev.azure.com/143it/Head_Office/_git/Head_Office
```

**Branch Naming Convention:**

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<ticket>-<description>` | `feature/1234-add-login-page` |
| Bug fix | `bugfix/<ticket>-<description>` | `bugfix/1235-fix-null-reference` |
| Hotfix | `hotfix/<ticket>-<description>` | `hotfix/1236-security-patch` |
| Release | `release/<version>` | `release/1.2.0` |

**Commit Message Format:**

```
<type>(<scope>): <subject>

<body>

<footer>

# Types: feat, fix, docs, style, refactor, test, chore
# Example:
feat(auth): add password reset functionality

Implement password reset flow with email verification.
Includes new ResetPassword API endpoint and email template.

Closes #1234
```

### 3.4 Pull Request Guidelines

**Creating a PR:**

```bash
# Create feature branch
git checkout -b feature/1234-new-feature

# Make changes and commit
git add .
git commit -m "feat(module): add new feature"

# Push branch
git push -u origin feature/1234-new-feature

# Create PR via CLI
az repos pr create \
  --title "feat(module): add new feature" \
  --description "Description of changes" \
  --source-branch feature/1234-new-feature \
  --target-branch main \
  --work-items 1234
```

**PR Checklist:**

- [ ] Title follows commit message format
- [ ] Description explains what and why
- [ ] Work item linked
- [ ] All tests passing
- [ ] Self-review completed
- [ ] Screenshots/videos for UI changes
- [ ] Documentation updated if needed

### 3.5 Code Review Process

**As an Author:**
1. Create PR with complete description
2. Self-review before requesting reviews
3. Add appropriate reviewers (min 2)
4. Respond to feedback within 24 hours
5. Resolve all comments before merging

**As a Reviewer:**
1. Review within 4 hours of assignment
2. Use constructive feedback
3. Approve only when satisfied
4. Use "Request changes" for blocking issues
5. Suggest improvements, don't dictate style

**Review Feedback Levels:**

| Prefix | Meaning | Action Required |
|--------|---------|-----------------|
| `[blocking]` | Must fix before merge | Yes |
| `[suggestion]` | Consider this improvement | Optional |
| `[question]` | Clarification needed | Respond |
| `[nit]` | Minor style issue | Optional |

---

## 4. QA Engineer Onboarding

### 4.1 QA Training Schedule

**Week 1:**

| Day | Morning | Afternoon |
|-----|---------|-----------|
| Mon | Environment setup | Core training: Azure DevOps |
| Tue | Azure Test Plans overview | Test case management |
| Wed | Test automation tools | E2E testing setup |
| Thu | Bug reporting workflow | First test run (guided) |
| Fri | Performance testing intro | Security testing intro |

### 4.2 Azure Test Plans Training

**Creating Test Plans:**

1. Navigate to Test Plans in Azure DevOps
2. Create new Test Plan for sprint/release
3. Add Test Suites (by feature area)
4. Create or import Test Cases

**Test Case Template:**

```markdown
# Test Case: [TC-XXXX]

## Title
[Clear description of what is being tested]

## Prerequisites
- [Prerequisite 1]
- [Prerequisite 2]

## Test Steps
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | [Action] | [Expected outcome] |
| 2 | [Action] | [Expected outcome] |

## Test Data
- User: test.user@143it.com
- Environment: Staging

## Attachments
- [Screenshots, test data files]
```

### 4.3 Bug Reporting Guidelines

**Bug Report Template:**

```markdown
# Bug: [Brief Title]

## Environment
- Environment: [Dev/Staging/Prod]
- Browser/Device: [Chrome 120, Windows 11]
- Build Version: [1.2.3]

## Steps to Reproduce
1. Navigate to [URL]
2. Click on [Element]
3. Enter [Data]
4. Observe [Behavior]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Impact
- Severity: [Critical/High/Medium/Low]
- Affected Users: [All/Some/Specific]
- Workaround: [Yes/No - describe if yes]

## Evidence
- [ ] Screenshot attached
- [ ] Video attached (for complex repro)
- [ ] Logs attached

## Related
- Story/Feature: AB#1234
- Related Bugs: AB#1235
```

### 4.4 Test Automation Setup

**Playwright Setup:**

```bash
# Install Playwright
npm init playwright@latest

# Configure for CI
npx playwright install --with-deps chromium

# Run tests
npx playwright test

# View report
npx playwright show-report
```

**Test Organization:**

```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   └── logout.spec.ts
│   ├── features/
│   │   ├── dashboard.spec.ts
│   │   └── profile.spec.ts
│   └── smoke/
│       └── health-check.spec.ts
├── fixtures/
│   └── test-data.json
└── playwright.config.ts
```

---

## 5. Operations Engineer Onboarding

### 5.1 Operations Training Schedule

**Week 1:**

| Day | Morning | Afternoon |
|-----|---------|-----------|
| Mon | Environment setup | Core training: Azure DevOps |
| Tue | Azure infrastructure overview | Pipeline management |
| Wed | Monitoring & alerting | Log analysis |
| Thu | Incident response training | On-call procedures |
| Fri | Disaster recovery procedures | Security operations |

### 5.2 Infrastructure Overview

**Key Azure Resources:**

```
┌─────────────────────────────────────────────────────────────┐
│                    143it Azure Environment                  │
├─────────────────────────────────────────────────────────────┤
│  Resource Groups                                            │
│  ├── rg-devops-prod     (Azure DevOps agents, artifacts)   │
│  ├── rg-app-prod        (Production application)           │
│  ├── rg-app-staging     (Staging environment)              │
│  ├── rg-app-dev         (Development environment)          │
│  ├── rg-shared          (Key Vault, Log Analytics)         │
│  └── rg-networking      (VNet, NSGs, private endpoints)    │
└─────────────────────────────────────────────────────────────┘
```

**Essential CLI Commands:**

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "143it-Production"

# List resources in group
az resource list --resource-group rg-app-prod --output table

# Check App Service status
az webapp show --resource-group rg-app-prod --name app-prod --query state

# Stream logs
az webapp log tail --resource-group rg-app-prod --name app-prod

# Scale App Service
az webapp scale --resource-group rg-app-prod --name app-prod --instance-count 3
```

### 5.3 Monitoring & Alerting

**Key Dashboards:**

| Dashboard | Purpose | URL |
|-----------|---------|-----|
| Application Health | App performance, errors | Azure Portal > Dashboard |
| Pipeline Status | Build/release status | Azure DevOps > Pipelines |
| Infrastructure | Resource health, costs | Azure Portal > Dashboard |
| Security | Security alerts, compliance | Azure Security Center |

**Alert Response:**

```
Alert Received
     │
     ├── Acknowledge within 5 minutes
     │
     ├── Assess severity
     │   ├── Sev 0: Immediate escalation
     │   ├── Sev 1: Investigate + escalate if needed
     │   ├── Sev 2: Investigate during business hours
     │   └── Sev 3: Log and monitor
     │
     ├── Follow runbook (operational_runbooks.md)
     │
     └── Update incident ticket
```

### 5.4 On-Call Training

**Before first on-call shift:**

- [ ] Complete operational runbooks review
- [ ] Shadow on-call engineer for 1 week
- [ ] Practice incident response in staging
- [ ] Verify access to all monitoring systems
- [ ] Test alerting (receive test page)
- [ ] Review recent incident reports

**On-Call Checklist:**

```markdown
## Start of Shift
- [ ] Verify monitoring dashboards accessible
- [ ] Check for any ongoing incidents
- [ ] Review any notes from previous shift
- [ ] Confirm escalation contacts available

## During Shift
- [ ] Acknowledge alerts within 5 minutes
- [ ] Document all actions taken
- [ ] Escalate per escalation matrix
- [ ] Update stakeholders as needed

## End of Shift
- [ ] Handoff any active incidents
- [ ] Document shift summary
- [ ] Note any recurring issues
```

---

## 6. DevOps Champion Program

### 6.1 Champion Role

**Purpose:** DevOps Champions are team representatives who:
- Act as first point of contact for DevOps questions
- Help team members adopt new practices
- Provide feedback on tooling and processes
- Facilitate training sessions

### 6.2 Champion Selection Criteria

| Criterion | Description |
|-----------|-------------|
| Experience | 6+ months with Azure DevOps |
| Competency | Passed competency assessment |
| Interest | Volunteers or nominated |
| Communication | Strong communication skills |
| Availability | Can dedicate ~4 hours/week |

### 6.3 Champion Responsibilities

| Responsibility | Frequency | Time Commitment |
|----------------|-----------|-----------------|
| Answer team questions | Daily | 30 min/day |
| Attend Champion sync | Weekly | 1 hour |
| Conduct team training | Monthly | 2 hours |
| Document tribal knowledge | Ongoing | 1 hour/week |
| Provide feedback | Quarterly | 1 hour |

### 6.4 Champion Training

**Additional Training for Champions:**

| Module | Duration | Content |
|--------|----------|---------|
| Advanced Pipelines | 2 hours | YAML templates, multi-stage |
| Train-the-Trainer | 2 hours | Effective knowledge transfer |
| Troubleshooting Deep Dive | 2 hours | Advanced debugging |
| Process Improvement | 1 hour | Kaizen, retrospectives |

---

## 7. Competency Assessment

### 7.1 Assessment Timing

| Assessment | When | Required Score |
|------------|------|----------------|
| Initial | Day 30 | 70% |
| Follow-up (if needed) | Day 45 | 80% |
| Annual refresh | Yearly | 80% |

### 7.2 Developer Competency Checklist

```markdown
## Developer Competency Assessment

### Git & Source Control (Required: 100%)
- [ ] Clone repository
- [ ] Create feature branch
- [ ] Make commits with proper messages
- [ ] Create pull request
- [ ] Respond to code review feedback
- [ ] Resolve merge conflicts
- [ ] Squash and merge PR

### Azure DevOps (Required: 80%)
- [ ] Navigate organization/project
- [ ] Create and update work items
- [ ] Link work items to PRs
- [ ] View pipeline status
- [ ] Read pipeline logs
- [ ] Access artifacts
- [ ] Use Azure Boards queries

### Code Quality (Required: 80%)
- [ ] Write unit tests
- [ ] Achieve >80% code coverage
- [ ] Pass SAST scan
- [ ] Fix code review issues
- [ ] Follow coding standards

### Security (Required: 100%)
- [ ] Never commit secrets
- [ ] Use Key Vault for secrets
- [ ] Follow secure coding guidelines
- [ ] Report security issues properly
```

### 7.3 QA Competency Checklist

```markdown
## QA Competency Assessment

### Test Management (Required: 100%)
- [ ] Create test plans
- [ ] Write test cases
- [ ] Execute test runs
- [ ] Report bugs properly
- [ ] Link tests to requirements

### Test Automation (Required: 80%)
- [ ] Set up test project
- [ ] Write automated tests
- [ ] Run tests locally
- [ ] Integrate with pipeline
- [ ] Analyze test reports

### Azure DevOps (Required: 80%)
- [ ] Navigate Test Plans
- [ ] Use Boards effectively
- [ ] View pipeline test results
- [ ] Query work items
```

### 7.4 Operations Competency Checklist

```markdown
## Operations Competency Assessment

### Azure Infrastructure (Required: 90%)
- [ ] Navigate Azure Portal
- [ ] Use Azure CLI effectively
- [ ] Manage App Services
- [ ] Configure Key Vault
- [ ] Read and query logs

### Monitoring & Alerting (Required: 100%)
- [ ] Access monitoring dashboards
- [ ] Interpret metrics
- [ ] Respond to alerts
- [ ] Create custom queries

### Incident Response (Required: 100%)
- [ ] Follow incident procedures
- [ ] Escalate appropriately
- [ ] Document incidents
- [ ] Conduct post-incident review

### Pipelines (Required: 80%)
- [ ] Trigger deployments
- [ ] Monitor pipeline status
- [ ] Troubleshoot failures
- [ ] Perform rollbacks
```

---

## 8. Ongoing Training

### 8.1 Continuous Learning

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Team knowledge share | Bi-weekly | Rotating |
| Tool updates training | As needed | Champions |
| New process training | As released | DevOps team |
| External certifications | Optional | Individual |

### 8.2 Recommended Certifications

| Certification | Role | Provider |
|---------------|------|----------|
| AZ-400: DevOps Engineer Expert | All | Microsoft |
| AZ-104: Azure Administrator | Operations | Microsoft |
| GitHub Actions Certification | Developers | GitHub |
| Certified Kubernetes Administrator | Operations | CNCF |

### 8.3 Training Resources

**Internal Resources:**
- Azure DevOps Wiki (documentation)
- Recorded training sessions (Teams)
- Runbooks and procedures
- Champion office hours

**External Resources:**
- [Microsoft Learn - Azure DevOps](https://learn.microsoft.com/en-us/training/browse/?products=azure-devops)
- [Azure DevOps Labs](https://azuredevopslabs.com/)
- [GitHub Learning Lab](https://lab.github.com/)

### 8.4 Feedback & Improvement

**Onboarding Survey (Day 30):**

```markdown
## Onboarding Feedback Survey

Rate 1-5 (1=Poor, 5=Excellent):

1. Overall onboarding experience: [ ]
2. Quality of documentation: [ ]
3. Support from team/buddy: [ ]
4. Clarity of expectations: [ ]
5. Access to required tools: [ ]

What went well?
[Free text]

What could be improved?
[Free text]

Would you recommend any changes to the onboarding process?
[Free text]
```

**Quarterly Training Review:**

- Analyze competency assessment results
- Review common support questions
- Update training materials
- Add new modules for tool updates
- Incorporate feedback from surveys
