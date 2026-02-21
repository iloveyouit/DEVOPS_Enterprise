# Azure DevOps Enterprise Implementation Checklist for 143it

> **Related:** [Architecture Plan](azure_devops_architecture_plan.md) | [Security Baseline](security_baseline.md) | [Change Management](change_management.md)

---

## RACI Matrix

| Phase                        | Development | QA  | Operations | Management |
| ---------------------------- | :---------: | :-: | :--------: | :--------: |
| Phase 1: Org Setup           |      C      |  I  |     R      |     A      |
| Phase 2: Head_Office Project |      R      |  C  |     C      |     A      |
| Phase 3: Work Items          |      R      |  C  |     I      |     A      |
| Phase 4: Sprint Planning     |      R      |  R  |     I      |     A      |
| Phase 5: Kanban Boards       |      R      |  C  |     C      |     A      |
| Phase 6: Repositories        |      R      |  I  |     C      |     A      |
| Phase 7: Pipelines           |      C      |  C  |     R      |     A      |
| Phase 8: Dashboards          |      C      |  C  |     R      |     A      |
| Phase 9: Extensions          |      I      |  I  |     R      |     A      |
| Phase 10: Governance         |      C      |  C  |     R      |     A      |

> **R** = Responsible · **A** = Accountable · **C** = Consulted · **I** = Informed

---

## Timeline & Dependencies

| Phase                        | Duration | Depends On     | Target Start | Target End |
| ---------------------------- | -------- | -------------- | ------------ | ---------- |
| Assessment                   | 1 week   | —              | Week 1       | Week 1     |
| Phase 1: Org Setup           | 1 week   | Assessment     | Week 2       | Week 2     |
| Phase 2: Head_Office Project | 1 week   | Phase 1        | Week 3       | Week 3     |
| Phase 3: Work Items          | 1 week   | Phase 2        | Week 4       | Week 4     |
| Phase 4: Sprint Planning     | 1 week   | Phase 3        | Week 5       | Week 5     |
| Phase 5: Kanban Boards       | 1 week   | Phase 3        | Week 5       | Week 5     |
| Phase 6: Repositories        | 2 weeks  | Phase 1        | Week 3       | Week 4     |
| Phase 7: Pipelines           | 2 weeks  | Phase 6        | Week 5       | Week 6     |
| Phase 8: Dashboards          | 1 week   | Phases 4, 5, 7 | Week 7       | Week 7     |
| Phase 9: Extensions          | 1 week   | Phase 1        | Week 7       | Week 7     |
| Phase 10: Governance         | Ongoing  | Phase 7        | Week 8       | Week 8+    |

> **Total estimated timeline: 8 weeks** from kickoff to baseline governance in place.

---

## Risk Register

| #   | Risk                                      | Likelihood | Impact | Mitigation                                                              |
| --- | ----------------------------------------- | :--------: | :----: | ----------------------------------------------------------------------- |
| 1   | Azure AD misconfiguration locks out users |   Medium   |  High  | Test in staging tenant first; keep break-glass admin account            |
| 2   | GitHub integration fails or loses data    |    Low     |  High  | Mirror repos before any migration; keep GitHub repos read-only          |
| 3   | Teams resist process change               |    High    | Medium | Phased rollout; training sessions per team; appoint champions           |
| 4   | Licensing costs exceed budget             |   Medium   | Medium | Audit seat usage before purchase; use Stakeholder access where possible |
| 5   | Pipeline complexity delays go-live        |   Medium   | Medium | Start with simple CI; iterate to full CD over sprints                   |
| 6   | Loss of commit history during migration   |    Low     |  High  | Use `git clone --mirror`; verify counts before archiving source         |

---

## Success Criteria per Phase

| Phase      | Done When                                                          |
| ---------- | ------------------------------------------------------------------ |
| Assessment | All current-state items documented, gaps list signed off           |
| Phase 1    | Org accessible via Azure AD SSO, security policies enforced        |
| Phase 2    | Head_Office project created with correct process, teams configured |
| Phase 3    | Work item hierarchy functional, backlog populated with ≥ 1 Epic    |
| Phase 4    | First sprint created, capacity set, burndown widget visible        |
| Phase 5    | Kanban boards configured with WIP limits, card styles applied      |
| Phase 6    | At least 1 repo active with branch policies on `main`              |
| Phase 7    | CI pipeline triggers on PR, CD deploys to Dev environment          |
| Phase 8    | Team dashboard live with ≥ 5 widgets, stakeholder access verified  |
| Phase 9    | Core extensions installed, Teams notifications firing              |
| Phase 10   | Audit logging enabled, operational procedures documented           |

---

## Current Environment Assessment

### Azure AD

- [x] Verify 143it.com domain is active in Azure AD
- [x] Confirm Azure AD Premium P1 licensing
- [x] Check existing user accounts
- [x] Review existing security groups

### Azure DevOps

- [x] Locate existing Azure DevOps Organization
- [x] Document current projects and structure
- [x] Review current users and permissions
- [x] Check billing and licensing status

### GitHub

- [x] Audit github.com/iloveyouit organization
- [x] List all repositories
- [x] Document team structure
- [x] Review branch protection rules

---

## Phase 1: Azure DevOps Organization Setup

### Organization Configuration

- [x] Rename/create organization to 143it
- [x] Configure organization settings
- [x] Set up Azure AD connection
- [x] Configure security policies
- [x] Enable/disable extensions
- [x] Set up billing (if needed)

### Access Management

- [x] Create Azure AD group mapping
- [x] Configure default access levels
- [x] Set up project collection administrators
- [x] Review and audit user access

---

## Phase 2: Head_Office Project Setup (Gold Standard)

### Project Creation

- [x] Create Head_Office project
- [x] Select Agile process template
- [x] Configure project settings
- [x] Set up visibility (private/public)

### Team Structure

- [x] Create Development team
- [x] Create QA team
- [x] Create Operations team
- [x] Create Management team
- [x] Configure team permissions
- [x] Set up team areas

### Iteration Configuration

- [x] Define sprint cadence (2-week sprints recommended)
- [x] Configure iteration start/end dates
- [x] Set up release trains (if applicable)
- [x] Configure capacity planning defaults

---

## Phase 3: Work Item Configuration

### Work Item Types

- [ ] Configure Epics
- [ ] Configure Features
- [ ] Configure User Stories
- [ ] Configure Tasks
- [ ] Configure Bugs
- [ ] Configure Impediments

### Custom Fields (Optional)

- [ ] Add custom fields for business needs
- [ ] Configure field rules
- [ ] Set up picklists

### Backlog Configuration

- [ ] Configure portfolio backlogs
- [ ] Set up requirement hierarchy
- [ ] Configure backlog levels

---

## Phase 4: Sprint Planning Setup

### Sprint Configuration

- [ ] Create first sprint (Sprint 1)
- [ ] Set sprint capacity for each team
- [ ] Configure sprint burndown
- [ ] Set up sprint review meetings
- [ ] Configure sprint retrospectives

### Work Item Workflow

- [ ] Define state transitions
- [ ] Configure workflow rules
- [ ] Set up auto-state changes

---

## Phase 5: Kanban Board Configuration

### Board Setup

- [ ] Configure Development board
- [ ] Configure QA board
- [ ] Configure Operations board
- [ ] Customize columns

### WIP Limits & Swimlanes

- [ ] Set WIP limits per column
- [ ] Configure swimlanes by team/person
- [ ] Set up card colors by type/priority
- [ ] Configure card styling
- [ ] Add age indicators

### Advanced Features

- [ ] Enable cumulative flow diagram
- [ ] Configure forecast
- [ ] Set up card annotations

---

## Phase 6: Repository Configuration

### Azure Repos Setup (if using Azure Repos)

- [ ] Create main repository
- [ ] Set up branch strategy
- [ ] Configure branch policies
- [ ] Create PR templates
- [ ] Set up branch permissions

### OR GitHub Integration

- [ ] Connect GitHub organization
- [ ] Authorize repositories
- [ ] Configure GitHub service connection
- [ ] Set up GitHub branch policies

---

## Phase 7: Pipeline Configuration

### Build Pipelines

- [x] Create build pipeline template
- [x] Configure CI triggers
- [x] Set up agent configuration
- [x] Configure test integration
- [x] Set up code coverage

### Release Pipelines

- [x] Create release pipeline
- [x] Configure Dev environment
- [x] Configure Staging environment
- [x] Configure Production environment
- [x] Set up approval gates
- [x] Configure variable groups
- [x] Set up secret management
- [x] Configure Infrastructure as Code (IaC) deployment
- [x] Implement strict "build once, deploy many" immutable artifact strategy

---

## Phase 8: Dashboards & Reporting

### Team Dashboards

- [ ] Create team dashboard
- [ ] Add sprint burndown widget
- [ ] Add sprint burnup widget
- [ ] Add cumulative flow diagram
- [ ] Add build quality widget
- [ ] Add work items widget

### Portfolio Views

- [ ] Create portfolio dashboard
- [ ] Configure rollup views
- [ ] Set up cross-project views

---

## Phase 9: Extensions & Integrations

### Recommended Extensions

- [ ] Install Azure Pipelines extensions
- [ ] Install Test Management extensions
- [ ] Install Wiki extensions
- [ ] Install Analytics extensions
- [ ] Install Slack/Teams integrations

### Third-Party Integrations

- [ ] Configure GitHub integration
- [ ] Configure ServiceNow (if needed)
- [ ] Configure monitoring tools

---

## Phase 10: Governance & Operations

### Security & Compliance

- [ ] Review audit logs
- [ ] Configure security policies
- [ ] Set up compliance reporting
- [ ] Document security procedures

### Operational Procedures

- [ ] Create sprint planning procedure
- [ ] Document daily standup process
- [ ] Create sprint review template
- [ ] Document release process
- [ ] Set up incident response

---

## Next Steps After Head_Office

- [ ] Document lessons learned
- [ ] Create project templates
- [ ] Document migration path for future projects
- [ ] Train teams on the Head_Office model
- [ ] Plan expansion to other business units
