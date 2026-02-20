# Disaster Recovery & Backup Plan — 143it Azure DevOps

## 1. Backup Strategy

### Azure DevOps Data

| Data Type               | Backup Method                                    | Frequency         | Retention  |
| ----------------------- | ------------------------------------------------ | ----------------- | ---------- |
| **Git Repos**           | Git clone mirrors to secondary storage           | Daily (automated) | 90 days    |
| **Work Items**          | Azure DevOps REST API export (JSON)              | Weekly            | 1 year     |
| **Pipelines**           | YAML pipeline definitions in repo (self-backing) | On every commit   | Indefinite |
| **Wiki**                | Git-backed wiki clone                            | Daily             | 90 days    |
| **Artifacts/Packages**  | Azure Artifacts replication or NuGet mirror      | Weekly            | 6 months   |
| **Dashboards/Settings** | Manual export / documented configurations        | Quarterly         | 1 year     |

### GitHub Data

| Data Type             | Backup Method                          | Frequency        |
| --------------------- | -------------------------------------- | ---------------- |
| **Repositories**      | `gh repo clone --mirror` to Azure Blob | Daily            |
| **Actions workflows** | Stored in `.github/` within repos      | On every commit  |
| **Org settings**      | Documented in this repo                | Quarterly review |

## 2. Recovery Procedures

### Scenario: Repository Loss

1. Identify the latest mirror from backup storage
2. Create a new repo in Azure DevOps / GitHub
3. Push the mirror: `git push --mirror <new-remote>`
4. Reconfigure branch policies and permissions
5. Update pipeline service connections if needed
6. **RTO**: 1 hour | **RPO**: 24 hours (last daily mirror)

### Scenario: Pipeline Configuration Loss

1. YAML pipelines are restored automatically from repo
2. Classic pipelines: recreate from documented JSON export
3. Reconfigure variable groups and service connections
4. Re-run validation pipeline
5. **RTO**: 2 hours | **RPO**: Last commit

### Scenario: Work Item Data Loss

1. Import weekly JSON export via REST API
2. Re-link work items to commits and PRs
3. Verify sprint and board configurations
4. **RTO**: 4 hours | **RPO**: 7 days

### Scenario: Full Organization Recovery

1. Create new Azure DevOps organization
2. Re-establish Azure AD connection
3. Restore repos from mirrors
4. Import work items from JSON backups
5. Recreate teams, permissions, and area paths from documented config
6. Restore pipelines from YAML in repos
7. **RTO**: 1 business day | **RPO**: varies by data type

## 3. Automation

### Recommended Backup Script (Azure DevOps CLI)

```bash
#!/bin/bash
# Daily repo mirror backup
ORG="https://dev.azure.com/143it"
PROJECT="Head_Office"
BACKUP_DIR="/backups/azure-devops/$(date +%Y%m%d)"

mkdir -p "$BACKUP_DIR"

# Clone all repos as mirrors
az repos list --org "$ORG" --project "$PROJECT" --query "[].name" -o tsv | while read repo; do
    git clone --mirror "$ORG/$PROJECT/_git/$repo" "$BACKUP_DIR/$repo.git"
done

# Export work items
az boards query --wiql "SELECT [System.Id] FROM WorkItems" --org "$ORG" --project "$PROJECT" -o json > "$BACKUP_DIR/work_items.json"
```

## 4. Testing & Validation

- [ ] Test repo restore from mirror quarterly
- [ ] Test work item import from JSON backup quarterly
- [ ] Document and review DR plan every 6 months
- [ ] Run tabletop DR exercise annually

## 5. Roles & Responsibilities

| Role                 | Responsibility                              |
| -------------------- | ------------------------------------------- |
| **Operations Team**  | Execute backups, monitor backup jobs        |
| **Management**       | Approve DR plan, fund backup infrastructure |
| **Development Team** | Ensure pipeline YAML is committed to repo   |
| **QA Team**          | Validate restored environments              |
