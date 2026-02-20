# Enterprise Azure DevOps Setup for 143it - Comprehensive LLM Prompt

## Context

You are an enterprise DevOps architect helping 143it (a company operating at 143it.com) transition to an enterprise-level operation using Azure DevOps. The company has Azure and Microsoft 365 already in place using the 143it.com domain. You need to create a comprehensive architecture and implementation plan.

## Current State

- **Azure AD / M365**: Active under 143it.com domain
- **Azure DevOps Organization**: Exists but needs restructuring
- **GitHub**: Exists under github.com/iloveyouit (needs to be integrated)
- **Primary Project**: Head_Office (to be used as gold standard)
- **Teams**: Development, QA, Operations, Management
- **Parent Company**: 143it (primary domain: 143it.com)

## Requirements

Create a detailed enterprise setup plan that includes:

### 1. Azure DevOps Organization Configuration

- Organization settings and structure
- Security and access management
- Billing and licensing
- Policies and permissions
- Integration with Azure AD (143it.com)

### 2. Project Structure (Head_Office as Gold Standard)

- Project creation and configuration
- Process template selection (Agile/Scrum)
- Team structure and area paths
- Iteration paths and sprint cadence
- Project-level settings
- Local Developer Experience (Dev Containers / Codespaces)

### 3. Sprint Planning & Work Items

- Work item types hierarchy (Epic → Feature → User Story → Task)
- Custom work item fields
- Sprint planning workflow
- Backlog management
- Sprint review and retrospective configuration
- Bug tracking workflow

### 4. Task Management

- Task creation and assignment
- Task hierarchy and breakdown
- Time tracking
- Capacity planning
- Sprint burndown/burnup charts
- Cumulative flow diagrams

### 5. Kanban Boards

- Board configuration per team
- Swimlanes and WIP limits
- Column customization
- Card styles and filters
- Card colors by type/priority
- Age and bottleneck indicators
- Definition of Done (DoD) on cards

### 6. Azure Repositories

- Repository structure and naming conventions
- Branch strategy (GitFlow, trunk-based, or hybrid)
- Branch policies and protection rules
- Pull request workflow
- Code review process
- Repository security
- Git hooks and automation

### 7. Azure Pipelines (CI/CD)

- Build pipeline configuration
- Release pipeline stages
- Deployment environments (Dev, Staging, Production)
- Agent pools and customization
- Task groups and templates
- Variable and secret management
- Approval gates
- Deployment strategies (blue-green, canary, rolling)
- Infrastructure as Code (IaC) integration
- Immutable artifact promotion ("build once, deploy many")

### 8. GitHub Integration

- Connecting github.com/iloveyouit to Azure DevOps
- GitHub Actions integration
- GitHub branch policies
- Webhook configuration
- Repository mirroring options
- GitHub Advanced Security integration

### 9. DevOps Connection Pipeline

- End-to-end workflow from code to deployment
- Integration between Boards, Repos, and Pipelines
- Artifacts management
- Package management
- Test integration

### 10. Dashboards & Reporting

- Team dashboards
- Portfolio management views
- Sprint reports
- Custom widgets
- Analytics and metrics
- Stakeholder access

### 11. Security & Compliance

- Azure AD group mapping
- Role-based access control (RBAC)
- Security policies
- Audit logging
- Compliance requirements and target frameworks (e.g., SOC2, ISO 27001)
- Automated secrets rotation policies
- Data residency

### 12. Extensions & Integrations

- Recommended extensions
- Third-party integrations
- Slack/Teams notifications
- ServiceNow integration
- JIRA integration options

## Output Format

Provide your response in a structured format:

1. **Executive Summary**: High-level overview
2. **Architecture Diagram**: Visual representation
3. **Step-by-Step Implementation Guide**: Numbered steps for each component
4. **Configuration Details**: Specific settings and values
5. **Best Practices**: Industry recommendations
6. **Migration Path**: How to transition from current state
7. **Recommendations**: Additional suggestions for enterprise operations

Include code snippets, JSON configurations, and screenshots descriptions where applicable.

## Important Considerations

- The Head_Office project should be the gold standard for all future projects
- Ensure all configurations are enterprise-grade
- Consider scalability for future growth
- Include governance and operational procedures
- Address both technical and process aspects
- Make recommendations for automation and efficiency
