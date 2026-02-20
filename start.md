# 143it Azure DevOps Enterprise — Getting Started

## Purpose

This repository contains the planning documents for migrating **143it** to an enterprise-grade Azure DevOps environment. The **Head_Office** project serves as the gold standard template for all future projects.

## Documents

### Core Planning

| File | Description |
|------|-------------|
| [azure_devops_architecture_plan.md](azure_devops_architecture_plan.md) | High-level architecture, team structure, and phased implementation plan |
| [enterprise_architecture_llm_prompt.md](enterprise_architecture_llm_prompt.md) | Comprehensive prompt for generating detailed implementation guidance |
| [implementation_checklist.md](implementation_checklist.md) | Phase-by-phase checklist tracking all setup tasks |
| [success_metrics.md](success_metrics.md) | DORA metrics, KPIs, and reporting cadence |

### Security & Compliance

| File | Description |
|------|-------------|
| [security_baseline.md](security_baseline.md) | RBAC, conditional access, and compliance controls |
| [security_controls_implementation.md](security_controls_implementation.md) | Technical security controls, encryption, vulnerability management |

### Operations & Deployment

| File | Description |
|------|-------------|
| [deployment_strategy.md](deployment_strategy.md) | Blue-green, canary, rolling deployments and promotion gates |
| [rollback_procedures.md](rollback_procedures.md) | Application, database, and infrastructure rollback guidance |
| [operational_runbooks.md](operational_runbooks.md) | Day-to-day procedures, troubleshooting, and incident handling |
| [change_management.md](change_management.md) | CAB process, change classification, and approval workflows |
| [monitoring_plan.md](monitoring_plan.md) | Observability, alerting, and incident response |
| [disaster_recovery_plan.md](disaster_recovery_plan.md) | Backup, restore, and disaster recovery procedures |

### Development & Testing

| File | Description |
|------|-------------|
| [testing_strategy.md](testing_strategy.md) | Test management, automation, and quality gates |
| [migration_runbook.md](migration_runbook.md) | Step-by-step GitHub → Azure DevOps migration guide |
| [training_onboarding.md](training_onboarding.md) | Team onboarding curriculum and competency assessment |

### Templates

| File | Description |
|------|-------------|
| [templates/pipeline-build-template.yml](templates/pipeline-build-template.yml) | Standard CI build pipeline template |
| [templates/pipeline-release-template.yml](templates/pipeline-release-template.yml) | Standard CD release pipeline template |
| [templates/pull-request-template.md](templates/pull-request-template.md) | Pull request description template |
| [templates/user-story-template.md](templates/user-story-template.md) | User story with acceptance criteria |
| [templates/bug-report-template.md](templates/bug-report-template.md) | Bug report format |
| [templates/incident-report-template.md](templates/incident-report-template.md) | Post-incident review template |
| [templates/sprint-planning-template.md](templates/sprint-planning-template.md) | Sprint planning checklist |

## Quick Start

1. Review the [Architecture Plan](azure_devops_architecture_plan.md) to understand the target state
2. Walk through the [Implementation Checklist](implementation_checklist.md) to see what's done and what's next
3. Use the [LLM Prompt](enterprise_architecture_llm_prompt.md) to generate detailed step-by-step guides for any phase
4. Review [Security Baseline](security_baseline.md) and [Security Controls](security_controls_implementation.md) for compliance
5. Use [Operational Runbooks](operational_runbooks.md) for day-to-day procedures
6. Follow [Change Management](change_management.md) for all production changes
7. New team members should start with [Training & Onboarding](training_onboarding.md)

## Prerequisites

- Azure AD tenant with 143it.com domain active
- M365 E3/E5 licensing
- Azure DevOps organization access
- GitHub organization access (github.com/iloveyouit)
