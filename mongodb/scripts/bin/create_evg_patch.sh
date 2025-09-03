#!/bin/bash

EVG_BASE_URL="https://spruce.mongodb.com/patch/"
EVG_PATCHES_FILE="$HOME/.evgPatches"

usage() {
    echo "Usage: $0 [--alias <alias>] [--finalize] [--uncommitted] [--open] [--addPRCommentWithEvgPatch] [--help|-h]"
    echo "  --alias <alias>    Specify an alias for the patch"
    echo "  --finalize         Finalize the patch immediately"
    echo "  --uncommitted      Include uncommitted changes in the patch"
    echo "  --open             Open the created patch in the browser"
    echo "  --addPRCommentWithEvgPatch  Add a comment with the last EVG patch to the PR"
    echo "  --help, -h         Show this help message"
    exit 1
}

alias=""
finalize=false
uncommitted=false
open=false
addPRCommentWithEvgPatch=false

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

JIRA_API_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_TICKET_PATTERN="[A-Z]+-[0-9]+"

# Get the branch name and JIRA ticket from the current git repository
branch=$(git rev-parse --abbrev-ref HEAD)

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

# cmd="evergreen patch --project mongodb-mongo-$baseBranch"
cmd="evergreen patch"
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
fi

echo "\nPatch created successfully"
patchId=$(echo "$patchInfo" | cut -d ',' -f 1)


# Add a comment to the PR with the last patch details
if [[ "$addPRCommentWithEvgPatch" == true ]]; then
    prComment=":evergreen_tree: [evg]($EVG_BASE_URL$patchId)"
    
    # Check if the `gh` command is available
    if ! command -v gh &> /dev/null; then
        echo "gh CLI is not installed. Cannot add PR comment."
        exit 1
    fi

    # Check if the current branch is associated with a PR
    if ! gh pr view --json number --jq .number > /dev/null 2>&1; then
        echo "No PR associated with the current branch: $branch"
        exit 1
    fi

    echo "\nAdding comment to PR with last EVG patch"
    echo "PR URL: $(gh pr view --json url --jq .url > /dev/null 2>&1)"

    gh pr comment --body "$prComment"
fi

if $open; then
    echo "Opening evg patch $EVG_BASE_URL$patchId"
    if command -v xdg-open &> /dev/null; then
        xdg-open "$EVG_BASE_URL$patchId" &> /dev/null
    elif command -v open &> /dev/null; then
        open "$EVG_BASE_URL$patchId" &> /dev/null
    else
        echo "No suitable command found to open the URL."
        exit 1
    fi
else
    echo "Evg patch: $EVG_BASE_URL$patchId"
fi

echo ""

# Save the patch information to the EVG_PATCHES_FILE to keep track of patches
echo "$branch,$patchInfo" >> "$EVG_PATCHES_FILE"
