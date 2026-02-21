#!/bin/bash
ORG="https://dev.azure.com/143IT/"
PROJECT="Head_Office"
EPIC_ID=58

create_feature_and_tasks() {
    local feature_title="$1"
    shift
    local tasks=("$@")
    
    echo "Creating Feature: $feature_title"
    local feature_out=$(az boards work-item create --title "$feature_title" --type "Feature" --project "$PROJECT" --organization "$ORG" --query "id" -o tsv)
    
    # Link feature to epic
    az boards work-item relation add --id $feature_out --relation-type Parent --target-id $EPIC_ID --organization "$ORG" -o table >/dev/null 2>&1
    
    for task in "${tasks[@]}"; do
        echo "  Creating User Story: $task"
        local story_out=$(az boards work-item create --title "$task" --type "User Story" --project "$PROJECT" --organization "$ORG" --query "id" -o tsv)
        
        # Link story to feature
        az boards work-item relation add --id $story_out --relation-type Parent --target-id $feature_out --organization "$ORG" -o table >/dev/null 2>&1
    done
}

# Phase 3
tasks3=(
    "Configure Epics, Features, User Stories, Tasks, Bugs, Impediments"
    "Add custom fields, Configure field rules, Set up picklists"
    "Configure portfolio backlogs, Set up requirement hierarchy, Configure backlog levels"
)
create_feature_and_tasks "Phase 3: Work Item Configuration" "${tasks3[@]}"

# Phase 4
tasks4=(
    "Create first sprint, Set sprint capacity, Configure sprint burndown"
    "Set up sprint review & retrospectives"
    "Define state transitions, workflow rules, auto-state changes"
)
create_feature_and_tasks "Phase 4: Sprint Planning Setup" "${tasks4[@]}"

# Phase 5
tasks5=(
    "Configure Dev, QA, Ops boards and columns"
    "Set WIP limits per column, Configure swimlanes"
    "Set up card colors, styling, age indicators"
    "Enable cumulative flow, configure forecast, card annotations"
)
create_feature_and_tasks "Phase 5: Kanban Board Configuration" "${tasks5[@]}"

# Phase 6
tasks6=(
    "Create main repository, Set up branch strategy, Configure branch policies"
    "Create PR templates, Set up branch permissions"
    "Connect GitHub organization, Authorize repositories, Configure service connections"
)
create_feature_and_tasks "Phase 6: Repository Configuration" "${tasks6[@]}"

# Phase 7
tasks7=(
    "Create build pipeline template, Configure CI triggers"
    "Set up agent configuration, test integration, code coverage"
    "Create release pipeline, Configure environments (Dev/Staging/Prod)"
    "Set up approval gates, variable groups, secret management"
    "Configure IaC deployment, Implement immutable artifact strategy"
)
create_feature_and_tasks "Phase 7: Pipeline Configuration" "${tasks7[@]}"

# Phase 8
tasks8=(
    "Create team dashboard, Add standard widgets (burndown, CFD, etc.)"
    "Create portfolio dashboard, Configure rollup views"
)
create_feature_and_tasks "Phase 8: Dashboards & Reporting" "${tasks8[@]}"

# Phase 9
tasks9=(
    "Install recommended extensions (Pipelines, Test, Wiki, Analytics)"
    "Install Slack/Teams integrations"
    "Configure third-party integrations (GitHub, ServiceNow, Monitoring)"
)
create_feature_and_tasks "Phase 9: Extensions & Integrations" "${tasks9[@]}"

# Phase 10
tasks10=(
    "Review audit logs, Configure security policies, compliance reporting"
    "Document operational procedures (sprint planning, release process, incident response)"
)
create_feature_and_tasks "Phase 10: Governance & Operations" "${tasks10[@]}"

echo "Done populating backlog."
