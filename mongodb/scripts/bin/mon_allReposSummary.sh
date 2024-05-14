#! /bin/bash

ROOT_PATH="/home/ubuntu/devel/mongo"
JIRA_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"

JIRA_TICKET_PATTERN="[A-Z]*-[0-9][0-9][0-9][0-9][0-9]"

BOLD="1"
NO_BOLD="0"
YELLOW="33"
BLUE="34"
PURPLE="35"
# FORMAT_BOLD="\e[${BOLD}m"
# FORMAT_BOLD_AND_GREEN="\e[${BOLD};${GREEN}m"
# FORMAT_BOLD_AND_RED="\e[${BOLD};${RED}m"
FORMAT_END="\e[${NO_BOLD}m"

if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
    currentBranch=$(git rev-parse --abbrev-ref HEAD)
fi

# Build the header for the directories table
FIRST_COLUMN_WIDTH=16
SECOND_COLUMN_WIDTH=25
THIRD_COLUMN_WIDTH=22
FOURTH_COLUMN_WIDTH=16
FIFTH_COLUMN_WIDTH=25
printf "%-${FIRST_COLUMN_WIDTH}s|%-${SECOND_COLUMN_WIDTH}s|%-${THIRD_COLUMN_WIDTH}s|%-${FOURTH_COLUMN_WIDTH}s|%-${FIFTH_COLUMN_WIDTH}s\n" "  DIR" "  BASED ON" "  BRANCH" "  STATUS" "  INFO"
printf %${FIRST_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${SECOND_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${THIRD_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${FOURTH_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${FIFTH_COLUMN_WIDTH}s |tr " " "-"
printf "\n"

commitBaseBlue=""
commitBaseYellow=""
commitBasePurple=""
branchBlue=""
branchYellow=""
branchPurple=""

# Iterate through all directories from $ROOT_PATH
for dir in $(find $ROOT_PATH -maxdepth 1 -type d -print0 | sort -z | xargs -0); do
    # Check if the directory is a git repository
    if [ -e "$dir/.git" ]; then
        pushd "$dir" > /dev/null
        dirName=$(echo $dir | awk -F/ '{print $NF}')
        
        # Get current branch
        branch=$(git rev-parse --abbrev-ref HEAD)

        gitDescribe=$(git describe --abbrev=0 $branch)

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
        baseCommit=$(git merge-base $baseBranch $branch)
        baseCommitDate=$(git log --format=%ad --date=short -1 $baseCommit)
        branchPointingBaseCommit=$(git branch --points-at $baseCommit)

        baseCommitSummary="$baseCommitDate, ${baseBranch:0:4}, ${baseCommit:0:5}"
        
        # Bold the current directory line
        if [[ ! -z "$currentBranch" ]] && [[ "$branch" == "$currentBranch" ]]; then
            formatBegin="* \e[${BOLD}"
            fst_column_width=$(($FIRST_COLUMN_WIDTH-2))
        else
            formatBegin="\e[${NO_BOLD}"
            fst_column_width=$FIRST_COLUMN_WIDTH
        fi

        # Extract the JIRA ticket from the branch name
        if [[ "$branch" =~ $JIRA_TICKET_PATTERN ]]; then
            jiraTicket="${BASH_REMATCH[0]}"
        else
            jiraTicket=""
        fi

        if [[ "$dir" =~ "mainLion" ]]; then
            FORMAT="${formatBegin};${YELLOW}m"
            commitBaseYellow="$baseCommit"
            branchYellow="$branch"
        elif [[ "$dir" =~ "mainStrawberry" ]]; then
            FORMAT="${formatBegin};${PURPLE}m"
            commitBasePurple="$baseCommit"
            branchPurple="$branch"
        elif [[ "$dir" =~ "mainSunset" ]]; then
            FORMAT="${formatBegin};${BLUE}m"
            commitBaseBlue="$baseCommit"
            branchBlue="$branch"
        else
            FORMAT="${formatBegin}m"
        fi
        
        # Get the jira ticket summary
        if [[ "$jiraTicket" != "" ]]; then
            response=$(curl -s "$JIRA_BASE_URL$jiraTicket")
            summary=$(echo "$response" | jq -r '.fields.summary') 
        else
            summary=""
        fi

        # Print a directory row
        if [[ -z "$summary" || "$summary" == "null" ]]; then
            printf "${FORMAT}%-${fst_column_width}s [%s] %s${FORMAT_END}\n" "$dirName" "$baseCommitSummary" "$branch"
        else
            jiraStatus=$(echo "$response" | jq -r '.fields.status.name')
            printf "${FORMAT}%-${fst_column_width}s [%s] %-${THIRD_COLUMN_WIDTH}s %-${FOURTH_COLUMN_WIDTH}s %-${FIFTH_COLUMN_WIDTH}s${FORMAT_END}\n" "$dirName" "$baseCommitSummary" "$branch" "$jiraStatus" "$summary"
        fi
        popd > /dev/null
    fi
done

# Build the header for the tickets table
FIRST_COLUMN_WIDTH=25
SECOND_COLUMN_WIDTH=25
THIRD_COLUMN_WIDTH=16
FOURTH_COLUMN_WIDTH=24
printf "\n\n"
printf "%-${FIRST_COLUMN_WIDTH}s|%-${SECOND_COLUMN_WIDTH}s|%-${THIRD_COLUMN_WIDTH}s|%-${FOURTH_COLUMN_WIDTH}s\n" "  BRANCH" "  BASED ON" "  STATUS" "  SUMMARY"
printf %${FIRST_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${SECOND_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${THIRD_COLUMN_WIDTH}s |tr " " "-"
printf "-"
printf %${FOURTH_COLUMN_WIDTH}s |tr " " "-"
printf "\n"

pushd "$ROOT_PATH" > /dev/null
for branch in $(git branch | grep -e 'suhu' ); do

    # Extract the JIRA ticket from the branch name
    if [[ "$branch" =~ $JIRA_TICKET_PATTERN ]]; then
        jiraTicket="${BASH_REMATCH[0]}"
    else
        jiraTicket=""
    fi

    if [[ "$jiraTicket" != "" ]]; then
        # Get the jira ticket summary and status
        response=$(curl -s "$JIRA_BASE_URL$jiraTicket")
        jiraSummary=$(echo "$response" | jq -r '.fields.summary') 
        jiraStatus=$(echo "$response" | jq -r '.fields.status.name')

        if [[ ! -z "$jiraSummary" && "$jiraSummary" != "null" ]]; then

            gitDescribe=$(git describe --abbrev=0 $branch)

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
            baseCommit=$(git merge-base $baseBranch $branch)
            baseCommitDate=$(git log --format=%ad --date=short -1 $baseCommit)
            branchPointingBaseCommit=$(git branch --points-at $baseCommit)

            baseCommitSummary="$baseCommitDate, ${baseBranch:0:4}, ${baseCommit:0:5}"

            # Get the appropiate format
            if [[ "$branchYellow" == "$branch" ]]; then
                format="\e[${BOLD};${YELLOW}m"
            elif [[ "$branchPurple" == "$branch" ]]; then
                format="\e[${BOLD};${PURPLE}m"
            elif [[ "$branchBlue" == "$branch" ]]; then
                format="\e[${BOLD};${BLUE}m"
            else
                format=""
            fi

            if [[ "$format" == "" ]]; then
                if [[ "$baseCommit" == "$commitBaseYellow" ]]; then
                    format="\e[${NO_BOLD};${YELLOW}m"
                elif [[ "$baseCommit" == "$commitBasePurple" ]]; then
                    format="\e[${NO_BOLD};${PURLPLW}m"
                elif [[ "$baseCommit" == "$commitBaseBlue" ]]; then
                    format="\e[${NO_BOLD};${BLUE}m"
                else
                    format="\e[${NO_BOLD}m"
                fi
            fi

            # Print a branch row
            printf "${format}%-${FIRST_COLUMN_WIDTH}s [%s] %-${THIRD_COLUMN_WIDTH}s %s${FORMAT_END}\n" "$branch" "$baseCommitSummary" "$jiraStatus" "$jiraSummary"
        fi
    fi
done
popd > /dev/null
