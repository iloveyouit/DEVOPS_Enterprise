# GitHub → Azure DevOps Migration Runbook

## Pre-Migration Checklist

- [ ] Inventory all repos in `github.com/iloveyouit`
- [ ] Identify repos to migrate vs. repos to keep on GitHub only
- [ ] Document current CI/CD pipelines per repo
- [ ] Identify active branches per repo
- [ ] Notify all contributors of the migration timeline
- [ ] Create service connections in Azure DevOps for GitHub

---

## Decision: Migrate Repos or Integrate?

| Option                        | When to Use                                          |
| ----------------------------- | ---------------------------------------------------- |
| **A — Mirror to Azure Repos** | Full ownership in Azure DevOps, no GitHub dependency |
| **B — GitHub Integration**    | Keep code on GitHub, use Azure Boards + Pipelines    |
| **C — Hybrid**                | Some repos in Azure Repos, some stay on GitHub       |

> **Recommendation**: Adopt a single source of truth. **Option A** (Full Mirror to Azure Repos) is recommended to align with the Head_Office gold standard and avoid split-brain governance branching/security policies. If GitHub is tightly integrated into the workflow, use **Option B** exclusively. Avoid **Option C**.

---

## Option A: Full Repo Migration

### Step 1 — Clone the Repository

```bash
git clone --mirror https://github.com/iloveyouit/<repo-name>.git
cd <repo-name>.git
```

### Step 2 — Create the Target Repo in Azure DevOps

```bash
az repos create --name <repo-name> --org https://dev.azure.com/143it --project Head_Office
```

### Step 3 — Push to Azure Repos

```bash
git push --mirror https://dev.azure.com/143it/Head_Office/_git/<repo-name>
```

### Step 4 — Verify

- [ ] All branches present
- [ ] All tags present
- [ ] Full commit history intact
- [ ] File sizes within limits

### Step 5 — Reconfigure CI/CD

- [ ] Update pipeline triggers to point to Azure Repos
- [ ] Migrate any GitHub Actions → Azure Pipelines YAML
- [ ] Update variable groups and secrets
- [ ] Run validation build

### Step 6 — Archive the GitHub Repo

- [ ] Set GitHub repo to read-only (archive)
- [ ] Add a `MOVED.md` with pointer to new location
- [ ] Update any documentation referencing the old URL

---

## Option B: GitHub Integration (Keep Code on GitHub)

### Step 1 — Create GitHub Service Connection

1. Azure DevOps → Project Settings → Service Connections
2. New Service Connection → GitHub
3. Authenticate with OAuth or PAT
4. Grant access to `iloveyouit` organization

### Step 2 — Connect Repos to Azure Boards

1. Install **Azure Boards** GitHub App on `iloveyouit` org
2. Configure linked repos
3. Use `AB#<id>` commit syntax to link commits to work items

### Step 3 — Connect Repos to Azure Pipelines

1. Create new pipeline → select GitHub as source
2. Authorize repository access
3. Configure YAML pipeline in the repo
4. Set up triggers (CI on push, PR validation)

### Step 4 — Configure Branch Policies on GitHub

- [ ] Require PR reviews (minimum 1 reviewer)
- [ ] Require status checks (Azure Pipelines build)
- [ ] Require signed commits (optional, recommended)
- [ ] Protect `main` branch from force push

---

## Post-Migration Validation

| Check             | Command / Action                            | Expected Result             |
| ----------------- | ------------------------------------------- | --------------------------- |
| Commit count      | `git rev-list --count HEAD` on both remotes | Match                       |
| Branch count      | `git branch -r \| wc -l`                    | Match                       |
| Pipeline trigger  | Push a test commit                          | Build triggers successfully |
| Work item linking | Commit with `AB#123`                        | Links to Azure Boards item  |
| PR workflow       | Open a PR                                   | Status checks run           |

---

## Rollback Plan

If migration fails or introduces issues:

1. Original GitHub repos remain untouched (read-only archive)
2. Remove Azure Repos mirror
3. Revert pipeline configurations to GitHub source
4. Communicate rollback to team

---

## Communication Plan

| When               | Who              | Message                                    |
| ------------------ | ---------------- | ------------------------------------------ |
| **2 weeks before** | All contributors | Migration announcement with timeline       |
| **1 week before**  | Dev + QA teams   | Freeze new long-lived branches on GitHub   |
| **Migration day**  | Operations       | Execute runbook, send status updates       |
| **Day after**      | All teams        | Confirm success, distribute new clone URLs |
| **1 week after**   | Management       | Post-migration review                      |
