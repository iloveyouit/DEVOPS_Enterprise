# Security Baseline — 143it Azure DevOps

## 1. Identity & Access Management

### Azure AD Integration

| Setting             | Configuration                               |
| ------------------- | ------------------------------------------- |
| **Authentication**  | Azure AD SSO via 143it.com                  |
| **MFA**             | Required for all users (Conditional Access) |
| **Guest Access**    | Disabled by default, exception-based        |
| **Session Timeout** | 8 hours inactive, 24 hours maximum          |

### Azure AD Security Groups → Azure DevOps Mapping

| Azure AD Group       | Azure DevOps Role                   | Access Level  |
| -------------------- | ----------------------------------- | ------------- |
| `AzDO-Admins`        | Project Collection Administrators   | Full          |
| `AzDO-ProjectAdmins` | Project Administrator (Head_Office) | Project Admin |
| `AzDO-Developers`    | Contributors (Head_Office)          | Basic         |
| `AzDO-QA`            | Contributors (Head_Office)          | Basic         |
| `AzDO-Operations`    | Contributors + Release Approvers    | Basic         |
| `AzDO-Stakeholders`  | Readers                             | Stakeholder   |

### Principle of Least Privilege

- No individual user permissions — all access through groups
- Elevate permissions only for the duration needed (JIT where possible)
- Review access quarterly

## 2. Conditional Access Policies

| Policy                | Target    | Conditions                 | Grant                     |
| --------------------- | --------- | -------------------------- | ------------------------- |
| **Require MFA**       | All users | All cloud apps             | MFA required              |
| **Block legacy auth** | All users | Legacy auth clients        | Block                     |
| **Compliant devices** | Admins    | Azure DevOps, Azure portal | Compliant device required |
| **Trusted locations** | All users | Outside corporate network  | MFA + compliant device    |

## 3. Azure DevOps Security Policies

### Organization-Level

- [ ] Disable third-party OAuth access
- [ ] Disable SSH authentication (unless required)
- [ ] Enable audit logging
- [ ] Restrict organization creation to admins
- [ ] Restrict PAT scope to minimum required

### Project-Level (Head_Office)

- [ ] Restrict "Create new repositories" to Project Admins
- [ ] Restrict "Delete repositories" to Collection Admins
- [ ] Configure branch policies on `main` (require PR, reviewers, build)
- [ ] Restrict pipeline editing to authorized users
- [ ] Restrict service connection access to specific pipelines

### PAT (Personal Access Token) Policy

| Rule             | Setting                           |
| ---------------- | --------------------------------- |
| Maximum lifetime | 90 days                           |
| Scope            | Minimum required per use case     |
| Audit            | Monthly review of active PATs     |
| Revocation       | Immediately on employee departure |

## 4. Repository Security

### Branch Policies (Main Branch)

| Policy                  | Setting                       |
| ----------------------- | ----------------------------- |
| Require pull request    | Yes                           |
| Minimum reviewers       | 2                             |
| Reset votes on new push | Yes                           |
| Include code owners     | Yes                           |
| Build validation        | Required (CI must pass)       |
| Comment resolution      | All comments must be resolved |
| Merge strategy          | Squash merge (recommended)    |

### Secrets Management

- **DO NOT** commit secrets, keys, or connection strings to repos
- Use Azure Key Vault for application secrets
- Use Azure DevOps Variable Groups (linked to Key Vault) for pipeline secrets
- Enable **GitHub Advanced Security** secret scanning if using GitHub
- Configure pre-commit hooks to detect secrets: `detect-secrets`
- Implement automated secrets rotation policy (e.g., 90 days for service principals, PATs, API keys)

## 5. Pipeline Security

### Service Connections

| Connection                          | Scope                   | Approval                 |
| ----------------------------------- | ----------------------- | ------------------------ |
| Azure Resource Manager (Dev)        | Dev subscription/RG     | None                     |
| Azure Resource Manager (Staging)    | Staging subscription/RG | None                     |
| Azure Resource Manager (Production) | Prod subscription/RG    | Manual approval required |
| GitHub                              | iloveyouit org          | Pipeline-specific access |

### Pipeline Permissions

- Pipelines can only access approved service connections
- Production deployments require manual approval from Operations
- Pipeline variables marked as secrets are non-readable

## 6. Audit & Compliance

### Audit Stream Configuration

- [ ] Enable Azure DevOps Audit Streaming
- [ ] Route audit logs to Log Analytics Workspace
- [ ] Configure retention: 1 year minimum
- [ ] Set up alerts for high-risk events:
  - Permission changes
  - New admin access granted
  - Service connection created/modified
  - Pipeline definition changes (Production)

### Compliance Checklist

- [ ] Document data classification policy
- [ ] Identify regulated data in repos (PII, financial)
- [ ] Configure data residency (Azure region selection)
- [ ] Define target compliance frameworks (e.g., SOC2, ISO 27001, HIPAA)
- [ ] Annual compliance review against target frameworks

## 7. Incident Response (Security)

| Step | Action                                                       | Owner                 |
| ---- | ------------------------------------------------------------ | --------------------- |
| 1    | Detect anomaly via audit logs or alert                       | Operations            |
| 2    | Isolate affected resources (disable accounts, revoke tokens) | Admins                |
| 3    | Investigate scope of breach                                  | Security + Operations |
| 4    | Remediate (rotate secrets, patch, update policies)           | All teams             |
| 5    | Post-incident report within 72 hours                         | Management            |
