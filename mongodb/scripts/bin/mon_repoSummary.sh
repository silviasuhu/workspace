#! /bin/bash

# Descriptions: This script prints a summary of a git repo including Jira and Git info
#
# Usage: mon_repoSummary.sh [repoDirName]
#  repoDirName: The name of the directory containing the repo placed under $GIT_TREE_PATH
#               If no parameter is passed, the current directory is assumed to be the repo

ROOT_PATH="$HOME/devel/mongo"

JIRA_API_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_BASE_URL="https://jira.mongodb.org/browse/"
JIRA_TICKET_PATTERN="[A-Z]*-[0-9][0-9][0-9][0-9][0-9]"

EVG_BASE_URL="https://spruce.mongodb.com/user/silvia.surroca/patches?page=0&patchName="

# Load util_scripts.sh to use `isRepoCompiled()` function
SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/../../../common/scripts/bashrc.d/util_scripts.sh

if [ -z "$1" ]; then
    dir=$(pwd)
else
    dir="$ROOT_PATH/$1"
fi

pushd "$dir" > /dev/null

branch=$(git rev-parse --abbrev-ref HEAD)

# Extract the JIRA ticket from the branch name
if [[ "$branch" =~ $JIRA_TICKET_PATTERN ]]; then
    jiraTicket="${BASH_REMATCH[0]}"
else
    jiraTicket=""
fi

# Extract the status, summary from Jira
jiraResponse=$(curl -s "$JIRA_API_BASE_URL$jiraTicket")
jiraStatus=$(echo $jiraResponse | jq -r ".fields.status.name")
jiraSummary=$(echo $jiraResponse | jq -r ".fields.summary")

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

# Get the base commit
baseCommit=$(git merge-base $baseBranch $branch)
branchesPointingBaseCommit=$(git branch --points-at $baseCommit)
branchesPointingBaseCommit="${branchesPointingBaseCommit:2}"

NORMAL="\e[0m"
BOLD="\e[1m"
UNDERLINE_AND_BLUE="\e[4;34m"
UNDERLINE_AND_GREEN="\e[4;32m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
PURPLE="\e[0;35m"

if [[ "$jiraStatus" == "Closed" ]]; then
    statusFormat="$RED"
else
    statusFormat=""
fi

baseDirName=$(basename $dir)
if [[ "$baseDirName" == "mainLion" ]]; then
    titleFormat="$YELLOW"
elif [[ "$baseDirName" == "mainStrawberry" ]]; then
    titleFormat="$PURPLE"
elif [[ "$baseDirName" == "mainSunset" ]]; then
    titleFormat="$BLUE"
else
    titleFormat="$BOLD"
fi

numFiles=$(git status --porcelain | wc -l)
if [[ "$numFiles" == "0" || -z "$numFiles" ]]; then
    tags="$tags[E] "
else
    tags="$tags[NE] "
fi

compiled=$(isRepoCompiled)
if [[ "$compiled" == "yes" ]]; then
    tags="$tags[B] "
else
    tags="$tags[NB] "
fi


echo ""
echo -e "${titleFormat}$jiraTicket ${statusFormat}($jiraStatus)${titleFormat} $tags${NORMAL}"
echo -e "${titleFormat}---------------------------------${NORMAL}"
echo -e "${titleFormat}$jiraSummary${NORMAL}"
echo ""
printf "%-17s %s\n" "Branch:" "$branch"
printf "%-17s %s\n" "Git describe:" "$gitDescribe"
printf "%-17s %s\n" "Based branch:" "$baseBranch"
printf "%-17s %s\n" "Based branches:" "$branchesPointingBaseCommit"
printf "%-17s %s\n" "Based commit:" "$(git log -1 --pretty=format:"%h - %ad: %s" --date=short $baseCommit)"
printf "%-17s %s\n" "Last commit:" "$(git log -1 --pretty=format:"%h - %ad: %s" --date=short)"
printf "%-17s %s\n" "Pending changes:" "$numFiles files"
printf "%-17s %s\n" "Compiled:" "$compiled"
echo ""
echo -e "JIRA LINK: ${UNDERLINE_AND_BLUE}$JIRA_BASE_URL$jiraTicket${NORMAL}"
echo -e "EVG LINK:  ${UNDERLINE_AND_GREEN}$EVG_BASE_URL$jiraTicket${NORMAL}"
echo ""

popd > /dev/null
