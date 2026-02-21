# 143IT Enterprise DevOps Architecture

## Overview

This repository serves as the single source of truth and "Gold Standard" template for transitioning **143IT** to an enterprise-grade Azure DevOps environment. It contains all architectural decisions, security baselines, deployment strategies, and phased implementation checklists required to build a compliant and scalable IT delivery mechanism.

The primary artifact of this initiative is the **Head_Office** project within Azure DevOps, which implements all the standards documented in this repository.

## Table of Contents

- **[Getting Started](start.md)**: Your primary entry point into the architecture.
- **[Implementation Checklist](implementation_checklist.md)**: A phase-by-phase tracker of all configurations and manual/automated steps to set up the environment.
- **[Azure DevOps Architecture Plan](azure_devops_architecture_plan.md)**: The structural design of the organization, projects, AD groups, and GitHub integration.
- **[Security Baseline](security_baseline.md) & [Controls](security_controls_implementation.md)**: Azure AD P1 mapping, Conditional Access, and time-boxed elevated access (manual JIT).
- **[Operational Runbooks](operational_runbooks.md) & [Change Management](change_management.md)**: Day-to-day procedures for operations and CAB approvals.
- **[Monitoring Plan](monitoring_plan.md)**: Observability using Log Analytics, Teams, and standard alerts.

## What's Going On (Project State)

As of the latest iteration, we have **automated** the deployment of the underlying infrastructure directly into Azure DevOps using the Azure CLI.

### What Has Been Completed:

1. **Azure AD Audit & Mapping**: Verified the `143it.com` domain with Azure AD Premium P1 licensing. Created strict Role-Based Access Control (RBAC) groups (e.g., `AzDO-Admins`, `AzDO-Developers`, `AzDO-ProdAccess`, `KV-Admins-Temp`).
2. **Organization Configuration**: Connected the Azure DevOps organization (`dev.azure.com/143IT`) directly to the Azure AD tenant.
3. **Head_Office Project Scaffolded**:
   - Initialized the "Gold Standard" project using the **Agile** template.
   - Created structural teams: `Development`, `QA`, `Operations`, and `Management`.
   - Set up Area Paths and the first iteration (`Sprint 1`).
4. **Agile Backlog Generated**: Programmatically translated the `implementation_checklist.md` into actionable Azure DevOps Epics, Features, and User Stories linked linearly inside the `Head_Office` board.

### What is Left to Execute (Next Steps):

- **Phase 6 - Repository Connection**: We need to authenticate the Azure Pipelines GitHub App to connect this documentation (and the other 49 repositories in `iloveyouit`) into Azure DevOps.
- **Phase 7 - Pipeline Configuration**: Constructing the YAML templates for CI/CD, configuring environments, and integrating Dev/Staging/Production gates.
- **Phase 8-10 - Governance**: Configuring dashboard widgets, setting up Teams notifications, and establishing the formal operational runbooks.

## How to Make Your First Commit

If you are reading this, you are likely preparing to push this architectural boilerplate into version control.

To formally sync this repository and preserve the architecture:

1. **Stage all modified and untracked files**:
   ```bash
   git add .
   ```
2. **Commit the setup phase**:
   ```bash
   git commit -m "feat: initialize enterprise architecture docs and completion of AzDO Phases 1-5"
   ```
3. **Push to the Remote Repository**:
   _(Whether this is bound to GitHub `github.com/iloveyouit` or the internal Azure DevOps `Head_Office` repo)_
   ```bash
   git push origin main
   ```

## Reference / LLM Prompt

If you are spinning up new projects or continuing automation, refer to the [Enterprise Architecture LLM Prompt](enterprise_architecture_llm_prompt.md) to contextualize future AI assistants with the current operational state.
