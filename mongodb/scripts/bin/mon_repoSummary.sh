#! /bin/bash

# Descriptions: This script prints a summary of a git repo including Jira and Git info
#
# Usage: mon_repoSummary.sh [repoDirName]
#  repoDirName: The name of the directory containing the repo placed under $GIT_TREE_PATH
#               If no parameter is passed, the current directory is assumed to be the repo

GIT_TREE_PATH="/home/ubuntu/devel/10gen-mongo"

if [ -z "$1" ]; then
    branch=$(git rev-parse --abbrev-ref HEAD)
    gitstatus=$(git status)
else
    pushd "$GIT_TREE_PATH/$repoDirName" > /dev/null
    branch=$(git rev-parse --abbrev-ref HEAD)
    gitstatus=$(git status)
    popd > /dev/null
fi

jiraId=$(echo "$branch" | awk -F/ '{print $NF}')
jiraUtils.sh -p -t "$jiraId"

echo "---------------------------------"
echo ""
echo "$gitstatus"
