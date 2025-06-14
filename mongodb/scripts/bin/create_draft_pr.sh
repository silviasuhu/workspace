#! /bin/bash

JIRA_API_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_TICKET_PATTERN="[A-Z]+-[0-9]+"

usage() {
    echo "Usage: $0 [--open] [--addPRCommentWithEvgPatch] [--help|-h]"
    echo "  --open - open the created draft PR in the browser"
    echo "  --addPRCommentWithEvgPatch - add a comment with the last EVG patch to the PR"
    echo "  --help, -h - show this help message"
    exit 1
}

open=false
addPRCommentWithEvgPatch=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --open)
            open=true
            shift
            ;;
        --addPRCommentWithEvgPatch)
            addPRCommentWithEvgPatch=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

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

if [[ $? -ne 0 ]]; then
    echo "Failed to create draft PR for branch: $branch"
    exit 1
fi

echo "\nDraft PR created successfully."
echo "You can view it at:"
gh pr view --json url --jq .url
echo ""

if [[ "$addPRCommentWithEvgPatch" == true ]]; then
    get_last_evg_patch.sh --addPRCommentWithEvgPatch
fi

# If the --open flag is set, open the created draft PR in the browser
if [[ "$open" == true ]]; then
    gh pr view --web
fi

echo ""