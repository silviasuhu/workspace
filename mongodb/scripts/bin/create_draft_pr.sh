#! /bin/bash

JIRA_API_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_TICKET_PATTERN="[A-Z]+-[0-9]+"

# Get the branch name and JIRA ticket from the current git repository
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" =~ $JIRA_TICKET_PATTERN ]]; then
    jiraTicket="${BASH_REMATCH[0]}"
else
    echo "No JIRA ticket found in branch name: $branch"
    exit 1
fi

# Get the base branch
gitDescribe=$(git describe --abbrev=0 $branch)
if [[ "$gitDescribe" == *"alpha"* ]]; then
    baseBranch="master"
else
    if [[ $gitDescribe =~ ^r([0-9]+)\.([0-9]+)\. ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
    else
        echo "Invalid version format: $gitDescribe got from branch: $branch"
        exit 1
    fi
    baseBranch="v$major.$minor"
fi

# Extract the status, summary from Jira
jiraResponse=$(curl -s "$JIRA_API_BASE_URL$jiraTicket")
jiraStatus=$(echo $jiraResponse | jq -r ".fields.status.name")
jiraSummary=$(echo $jiraResponse | jq -r ".fields.summary")

gh pr create --base $baseBranch --title "$jiraTicket $jiraSummary" --body "" --draft