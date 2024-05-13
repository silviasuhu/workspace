#! /bin/bash

ROOT_PATH="/home/ubuntu/devel/mongo"
JIRA_URL="https://jira.mongodb.org"

if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
    currentBranch=$(git rev-parse --abbrev-ref HEAD)
fi

bold=$(tput bold)
normal=$(tput sgr0)

# Iterate through all directories in the current directory
for dir in $(find $ROOT_PATH -maxdepth 1 -type d -print0 | sort -z | xargs -0); do
    # Check if the directory is a git repository
    if [ -e "$dir/.git" ]; then
        pushd "$dir" > /dev/null
        dirName=$(echo $dir | awk -F/ '{print $NF}')
        
        # Get current branch
        branch=$(git rev-parse --abbrev-ref HEAD)

        gitDescribe=$(git describe --abbrev=0 HEAD)

        # Get the base branch
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
        baseCommit=$(git merge-base $baseBranch HEAD)
        baseCommitDate=$(git log --format=%ad --date=short -1 $baseCommit)
        branchPointingBaseCommit=$(git branch --points-at $baseCommit)

        baseCommitSummary="$baseCommitDate, ${baseCommit:0:5}"
        
        # Hightligh the line if it's the current branch
        if [[ ! -z "$currentBranch" ]] && [[ "$branch" == "$currentBranch" ]]; then
            highlightStart="\e[32;1m* "
            highlightEnd="\e[32;0m"
            first_column_width=14
        else
            highlightStart=""
            highlightEnd=""
            first_column_width=16
        fi

        # Extract the JIRA ticket from the branch name
        jira_ticket=$(echo "$branch" | awk -F/ '{print $NF}')
        
        # Get the jira ticket summary
        response=$(curl -s "$JIRA_URL/rest/api/2/issue/$jira_ticket")
        summary=$(echo "$response" | jq -r '.fields.summary') 


        if [ -z "$summary" ] || [ "$summary" == "null" ]; then
            # echo -e "$highligh $dirName \t\t $branch"
            printf "${highlightStart}%-${first_column_width}s [%s] %s${highlightEnd}\n" "$dirName" "$baseCommitSummary" "$branch"
        else
            status=$(echo "$response" | jq -r '.fields.status.name')
            printf "${highlightStart}%-${first_column_width}s [%s] %s${highlightEnd}\n" "$dirName" "$baseCommitSummary" "$jira_ticket ($status), $summary"
        fi
        popd > /dev/null
    fi
done
