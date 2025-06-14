#!/bin/bash

usage() {
    echo "Usage: $0 [--open_jira] [--open_pr] [--open_evg] [--short] [--only-jira-url] [--only-pr-url] [--only-evg-url] [--help|-h] <directory>"
    echo "  --open_jira - open the JIRA ticket in the browser"
    echo "  --open_pr - open the PR in the browser"
    echo "  --open_evg - open the EVG patch in the browser"
    echo "  --short - print only JIRA URL, PR and EVG patch URL"
    echo "  --only-jira-url - print only JIRA URL"
    echo "  --only-pr-url - print only PR URL"
    echo "  --only-evg-url - print only EVG patch URL"
    echo "  --help, -h - show this help message"
    echo "  <directory> - the directory containing the repo (default: current directory)"
    exit 1
}

open_jira=false
open_pr=false
open_evg=false

get_dir_state=true
get_jira_url=true
get_jira_description=true
get_pr_url=true
get_evg_url=true

dir=$(pwd)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --open-jira)
            open_jira=true
            get_dir_state=false
            get_jira_url=false
            get_jira_description=false
            get_pr_url=false
            get_evg_url=false
            shift
            ;;
        --open-pr)
            open_pr=true
            get_dir_state=false
            get_jira_url=false
            get_jira_description=false
            get_pr_url=false
            get_evg_url=false
            shift
            ;;
        --open-evg)
            open_evg=true
            get_dir_state=false
            get_jira_url=false
            get_jira_description=false
            get_pr_url=false
            get_evg_url=false
            shift
            ;;
        --short)
            get_jira_description=false
            shift
            ;;
        --only-urls)
            get_jira_description=false
            get_dir_state=false
            shift
            ;;
        --only-jira-url)
            get_jira_description=false
            get_pr_url=false
            get_evg_url=false
            get_dir_state=false
            shift
            ;;
        --only-pr-url)
            get_jira_url=false
            get_jira_description=false
            get_evg_url=false
            get_dir_state=false
            shift
            ;;
        --only-evg-url)
            get_jira_url=false
            get_jira_description=false
            get_pr_url=false
            get_dir_state=false
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            dir="$ROOT_PATH/$1"
            if [[  ! -d "$dir" ]]; then
                echo "Unknown argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

ROOT_PATH="$HOME/devel/mongo"

JIRA_API_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_BASE_URL="https://jira.mongodb.org/browse/"
JIRA_TICKET_PATTERN="[A-Z]+-[0-9]+"

EVG_PATCHES_FILE="$HOME/.evgPatches"
EVG_BASE_URL="https://spruce.mongodb.com/patch/"

NORMAL="\e[0m"
BOLD="\e[1m"
UNDERLINE_AND_BLUE="\e[4;34m"
UNDERLINE_AND_GREEN="\e[4;32m"
UNDERLINE_AND_YELLOW="\e[4;33m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
PURPLE="\e[0;35m"

# Load util_scripts.sh to use `isRepoCompiled()` function
SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/../../../common/scripts/bashrc.d/util_scripts.sh

pushd "$dir" > /dev/null

branch=$(git rev-parse --abbrev-ref HEAD)

# Extract the JIRA ticket from the branch name
if [[ "$branch" =~ $JIRA_TICKET_PATTERN ]]; then
    jiraTicket="${BASH_REMATCH[0]}"
    jiraUrl=$JIRA_BASE_URL$jiraTicket
else
    jiraTicket=""
    jiraUrl="None"
fi

repoCompiled=$(isRepoCompiled)
tags=""
if [[ "$repoCompiled" == "yes" ]]; then
    tags="$tags[B] "
else
    tags="$tags[NB] "
fi

if [[ "$get_jira_description" == true && -n "$jiraTicket" ]]; then
    # Extract the status, summary from Jira
    jiraResponse=$(curl -s "$JIRA_API_BASE_URL$jiraTicket")
    jiraStatus=$(echo $jiraResponse | jq -r ".fields.status.name")
    jiraSummary=$(echo $jiraResponse | jq -r ".fields.summary")

    if [[ "$jiraStatus" == "Closed" ]]; then
        STATUS_FORMAT="$RED"
    else
        STATUS_FORMAT=""
    fi

    printf "\n"
    printf "${BOLD}$jiraTicket ${STATUS_FORMAT}($jiraStatus)${BOLD} $tags${NORMAL}\n"
    printf "${BOLD}---------------------------------${NORMAL}\n"
    printf "${BOLD}$jiraSummary${NORMAL}\n"
    printf "\n"

elif [[ "$get_jira_description" == true && -z "$jiraTicket" ]]; then

    printf "\n"
    printf "${BOLD}$branch $tags${NORMAL}\n"
    printf "${BOLD}---------------------------------${NORMAL}\n"
    printf "\n"
    printf "No JIRA ticket found in branch name: $branch\n"
    printf "\n"
fi

# Prints the repo state
if [[ "$get_dir_state" == true ]]; then
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

    # Get the PR state
    prState=$(gh pr view --json state -q .state 2> /dev/null)
    if [[ -z "$prState" ]]; then
        prState="N/A"
    fi

    printf "%-17s %s\n" "Branch:" "$branch"
    printf "%-17s %s\n" "Based branch:" "$baseBranch"
    printf "%-17s %s\n" "repoCompiled:" "$repoCompiled"
    printf "%-17s %s\n" "PR:" "$prState"
    printf "%-17s %s\n" "Git describe:" "$gitDescribe"
    printf "\n"
fi

# Prints the JIRA url:
if [[ "$get_jira_url" == true ]]; then
    printf "JIRA URL: ${UNDERLINE_AND_BLUE}$jiraUrl${NORMAL}\n"
fi

# Prints the PR url:
if [[ "$get_pr_url" == true ]]; then
    prUrl=$(gh pr view --json url -q .url 2> /dev/null)
    if [[ -z "$prUrl" ]]; then
        prUrl="None"
    fi
    printf "PR URL: ${UNDERLINE_AND_YELLOW}$prUrl${NORMAL}\n"
fi

# Prints the last evg patch url:
if [[ "$get_evg_url" == true ]]; then
    get_last_evg_patch.sh
fi

# Open PR in browser if requested
if [[ "$open_pr" == true ]]; then
    gh pr view --web
fi

# Open evg patch in browser if requested
if [[ "$open_evg" == true ]]; then
    get_last_evg_patch.sh --open
fi

# Open JIRA ticket in browser if requested
if [[ "$open_jira" == true ]]; then
    if [[ -n "$jiraUrl" ]]; then
        xdg-open "$jiraUrl" &> /dev/null || open "$jiraUrl" &> /dev/null
    else
        echo "No JIRA ticket found to open."
    fi
fi

popd > /dev/null
