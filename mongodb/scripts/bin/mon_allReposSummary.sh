#! /bin/bash

ROOT_PATH="/home/ubuntu/devel/10gen-mongo"
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
        
        # Check if that's the current branch
        highligh="${normal}"
        if [[ ! -z "$currentBranch" ]]; then
            if [[ "$branch" == "$currentBranch" ]]; then
                highligh="${bold}*"
            fi
        fi

        # Extract the JIRA ticket from the branch name
        jira_ticket=$(echo "$branch" | awk -F/ '{print $NF}')
        
        # Get the jira ticket information
        response=$(curl -s "$JIRA_URL/rest/api/2/issue/$jira_ticket")
        summary=$(echo "$response" | jq -r '.fields.summary') 

        if [ -z "$summary" ] || [ "$summary" == "null" ]; then
            echo "$highligh $dirName : $branch"
        else
            status=$(echo "$response" | jq -r '.fields.status.name')
            echo "$highligh $dirName : $jira_ticket ($status), $summary"
        fi
        popd > /dev/null
    fi
done
