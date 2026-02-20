# Azure DevOps Enterprise Implementation Checklist for 143it

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

### Azure AD / M365

- [ ] Verify 143it.com domain is active in Azure AD
- [ ] Confirm M365 licensing (E3/E5)
- [ ] Check existing user accounts
- [ ] Review existing security groups

### Azure DevOps

- [ ] Locate existing Azure DevOps Organization
- [ ] Document current projects and structure
- [ ] Review current users and permissions
- [ ] Check billing and licensing status

### GitHub

- [ ] Audit github.com/iloveyouit organization
- [ ] List all repositories
- [ ] Document team structure
- [ ] Review branch protection rules

---

## Phase 1: Azure DevOps Organization Setup

### Organization Configuration

- [ ] Rename/create organization to 143it
- [ ] Configure organization settings
- [ ] Set up Azure AD connection
- [ ] Configure security policies
- [ ] Enable/disable extensions
- [ ] Set up billing (if needed)

### Access Management

- [ ] Create Azure AD group mapping
- [ ] Configure default access levels
- [ ] Set up project collection administrators
- [ ] Review and audit user access

---

## Phase 2: Head_Office Project Setup (Gold Standard)

### Project Creation

- [ ] Create Head_Office project
- [ ] Select Agile process template
- [ ] Configure project settings
- [ ] Set up visibility (private/public)

### Team Structure

- [ ] Create Development team
- [ ] Create QA team
- [ ] Create Operations team
- [ ] Create Management team
- [ ] Configure team permissions
- [ ] Set up team areas

### Iteration Configuration

- [ ] Define sprint cadence (2-week sprints recommended)
- [ ] Configure iteration start/end dates
- [ ] Set up release trains (if applicable)
- [ ] Configure capacity planning defaults

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

- [ ] Create build pipeline template
- [ ] Configure CI triggers
- [ ] Set up agent configuration
- [ ] Configure test integration
- [ ] Set up code coverage

### Release Pipelines

- [ ] Create release pipeline
- [ ] Configure Dev environment
- [ ] Configure Staging environment
- [ ] Configure Production environment
- [ ] Set up approval gates
- [ ] Configure variable groups
- [ ] Set up secret management
- [ ] Configure Infrastructure as Code (IaC) deployment
- [ ] Implement strict "build once, deploy many" immutable artifact strategy

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
