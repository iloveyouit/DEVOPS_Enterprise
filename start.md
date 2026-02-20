# 143it Azure DevOps Enterprise — Getting Started

## Purpose

This repository contains the planning documents for migrating **143it** to an enterprise-grade Azure DevOps environment. The **Head_Office** project serves as the gold standard template for all future projects.

## Documents

| File                                    | Description                                                             |
| --------------------------------------- | ----------------------------------------------------------------------- |
| `azure_devops_architecture_plan.md`     | High-level architecture, team structure, and phased implementation plan |
| `enterprise_architecture_llm_prompt.md` | Comprehensive prompt for generating detailed implementation guidance    |
| `implementation_checklist.md`           | Phase-by-phase checklist tracking all setup tasks                       |
| `disaster_recovery_plan.md`             | Backup, restore, and disaster recovery procedures                       |
| `migration_runbook.md`                  | Step-by-step GitHub → Azure DevOps migration guide                      |
| `testing_strategy.md`                   | Test management, automation, and quality gates                          |
| `monitoring_plan.md`                    | Observability, alerting, and incident response                          |
| `security_baseline.md`                  | RBAC, conditional access, and compliance controls                       |
| `success_metrics.md`                    | DORA metrics, KPIs, and reporting cadence                               |

## Quick Start

1. Review the **Architecture Plan** to understand the target state
2. Walk through the **Implementation Checklist** to see what's done and what's next
3. Use the **LLM Prompt** to generate detailed step-by-step guides for any phase
4. Refer to supporting documents (DR, security, testing, etc.) for operational depth

## Prerequisites

- Azure AD tenant with 143it.com domain active
- M365 E3/E5 licensing
- Azure DevOps organization access
- GitHub organization access (github.com/iloveyouit)
