# Success Metrics & KPIs — 143it Azure DevOps

## 1. DORA Metrics (DevOps Research & Assessment)

The four key metrics that define elite DevOps performance:

| Metric                    | Definition                               | Target (Elite)           | Current Baseline | Measurement                            |
| ------------------------- | ---------------------------------------- | ------------------------ | ---------------- | -------------------------------------- |
| **Deployment Frequency**  | How often code is deployed to production | On demand (multiple/day) | TBD              | Azure Pipelines release analytics      |
| **Lead Time for Changes** | Time from commit to production           | < 1 hour                 | TBD              | Pipeline start → deploy timestamp      |
| **Change Failure Rate**   | % of deployments causing failure         | < 5%                     | TBD              | Failed deployments / total deployments |
| **Mean Time to Recovery** | Time to restore service after failure    | < 1 hour                 | TBD              | Incident open → resolved duration      |

### Performance Tiers

| Tier          | Deploy Frequency | Lead Time        | Change Failure Rate | MTTR         |
| ------------- | ---------------- | ---------------- | ------------------- | ------------ |
| 🥇 **Elite**  | On demand        | < 1 hour         | < 5%                | < 1 hour     |
| 🥈 **High**   | Daily–Weekly     | 1 day–1 week     | 6–15%               | < 1 day      |
| 🥉 **Medium** | Weekly–Monthly   | 1 week–1 month   | 16–30%              | 1 day–1 week |
| ⚠️ **Low**    | Monthly+         | 1 month–6 months | > 30%               | > 1 week     |

> **Goal**: Reach **High** tier within 6 months, **Elite** within 18 months.

## 2. Sprint Metrics

| Metric                | Target                                    | Dashboard Widget |
| --------------------- | ----------------------------------------- | ---------------- |
| **Sprint Velocity**   | Stable ± 10% per sprint                   | Velocity chart   |
| **Sprint Burndown**   | On track by mid-sprint                    | Burndown chart   |
| **Stories Completed** | ≥ 85% of committed stories                | Sprint summary   |
| **Carryover Rate**    | < 15% of sprint backlog                   | Manual tracking  |
| **Bug Escape Rate**   | < 5% of stories produce bugs post-release | Bug tracking     |

## 3. Code Quality Metrics

| Metric                     | Target                     | Tool                            |
| -------------------------- | -------------------------- | ------------------------------- |
| **Code Coverage**          | ≥ 80%                      | Azure Pipelines + coverage tool |
| **Technical Debt Ratio**   | < 5%                       | SonarQube / SonarCloud          |
| **Code Review Turnaround** | < 4 hours (business hours) | Azure Repos PR analytics        |
| **PR Size**                | < 400 lines changed        | PR policy / convention          |
| **Build Success Rate**     | ≥ 95%                      | Pipeline analytics              |

## 4. Operational Metrics

| Metric                       | Target         | Source                |
| ---------------------------- | -------------- | --------------------- |
| **Availability (SLA)**       | ≥ 99.9%        | Application Insights  |
| **Incident Count (Sev 0–1)** | ≤ 1 per month  | Azure DevOps Bugs     |
| **MTTR (all severities)**    | ≤ 4 hours      | Incident tracking     |
| **Backup Success Rate**      | 100%           | Backup job monitoring |
| **DR Test Pass Rate**        | 100% quarterly | DR exercise log       |

## 5. Team Health Metrics

| Metric                                | Measurement                                 | Frequency    |
| ------------------------------------- | ------------------------------------------- | ------------ |
| **Sprint Retrospective Satisfaction** | Team survey score (1–5)                     | Every sprint |
| **Onboarding Time**                   | Days for new dev to first PR                | Per new hire |
| **Documentation Currency**            | % of docs reviewed in last 90 days          | Quarterly    |
| **Cross-Training Coverage**           | % of components with ≥ 2 knowledgeable devs | Quarterly    |

## 6. Reporting Cadence

| Report                     | Audience                | Frequency   | Format                 |
| -------------------------- | ----------------------- | ----------- | ---------------------- |
| **Sprint Dashboard**       | Dev + QA                | Real-time   | Azure DevOps Dashboard |
| **DORA Metrics Report**    | Management              | Monthly     | PowerPoint / Wiki page |
| **Quality Report**         | All teams               | Per release | Azure DevOps Wiki      |
| **Security Audit**         | Management + Compliance | Quarterly   | Formal document        |
| **Annual DevOps Maturity** | Executive               | Annually    | Presentation           |

## 7. Establishing Baselines

### First 30 Days

- [ ] Instrument all pipelines with timestamps
- [ ] Start tracking deployment frequency manually
- [ ] Record current build success rate
- [ ] Set up Application Insights with availability tests
- [ ] Document current sprint velocity (last 3 sprints if available)

### 60 Days

- [ ] Calculate first DORA metric snapshot
- [ ] Establish code coverage baseline
- [ ] Measure average PR review turnaround
- [ ] Create first monthly DORA report

### 90 Days

- [ ] Set formal targets based on baselines
- [ ] Configure automated dashboard for DORA metrics
- [ ] Present first quarterly maturity assessment
- [ ] Adjust targets based on team capacity and trajectory
