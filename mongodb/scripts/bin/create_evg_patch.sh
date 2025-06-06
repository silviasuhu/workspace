#!/bin/bash

EVG_BASE_URL="https://spruce.mongodb.com/patch/"
EVG_PATCHES_FILE="$HOME/.evgPatches"

## We can receive 3 arguments: --alias <<alias>>, --finalize, --uncommitted
alias=""
finalize=false
uncommitted=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --alias)
            alias="$2"
            shift 2
            ;;
        --finalize)
            finalize=true
            shift
            ;;
        --uncommitted)
            uncommitted=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

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

cmd="evergreen patch --project mongodb-mongo-$baseBranch"
if [[ -n "$alias" ]]; then
    cmd="$cmd --alias $alias"
fi
if $finalize; then
    cmd="$cmd --finalize"
fi
if $uncommitted; then
    cmd="$cmd --uncommitted"
fi

echo "Running command: $cmd"

patchInfo=$($cmd --json | jq -r '.patch_id + "," + .create_time' 2>/dev/null)

if [[ -z "$patchInfo" ]]; then
    echo "Failed to create patch. Please check the command and try again."
    exit 1
else
    patchId=$(echo "$patchInfo" | cut -d ',' -f 1)
    echo "Patch created successfully"
    echo "$EVG_BASE_URL$patchId"
fi

echo "$branch,$patchInfo" >> "$EVG_PATCHES_FILE"
