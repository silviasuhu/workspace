#! /bin/bash

ROOT_PATH="$HOME/devel/mongo"
SNAPSHOT_FILE="$HOME/.reposSummary"
JIRA_BASE_URL="https://jira.mongodb.org/rest/api/2/issue/"
JIRA_TICKET_PATTERN="[A-Z]+-[0-9]+"

# Load util_scripts.sh to use `isRepoCompiled()` function
SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/../../../common/scripts/bashrc.d/util_scripts.sh

BOLD="1"
NO_BOLD="0"
GREEN="32"
YELLOW="33"
BLUE="34"
PURPLE="35"
# FORMAT_BOLD="\e[${BOLD}m"
# FORMAT_BOLD_AND_GREEN="\e[${BOLD};${GREEN}m"
# FORMAT_BOLD_AND_RED="\e[${BOLD};${RED}m"
FORMAT_END="\e[${NO_BOLD}m"

# Parse arguments
REFRESH=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-refresh)
      REFRESH=false
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ "$REFRESH" == false ]]; then
    cat $SNAPSHOT_FILE
    exit 0
fi

if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
    currentBranch=$(git rev-parse --abbrev-ref HEAD)
fi

# Build the header for the directories table
FIRST_COLUMN_WIDTH=24
SECOND_COLUMN_WIDTH=27
THIRD_COLUMN_WIDTH=29
FOURTH_COLUMN_WIDTH=16
FIFTH_COLUMN_WIDTH=25
{
    printf "%-${FIRST_COLUMN_WIDTH}s|%-${SECOND_COLUMN_WIDTH}s|%-${THIRD_COLUMN_WIDTH}s|%-${FOURTH_COLUMN_WIDTH}s|%-${FIFTH_COLUMN_WIDTH}s\n" "  DIR" "  BASED ON" "  BRANCH" "  STATUS" "  INFO"
    printf %${FIRST_COLUMN_WIDTH}s | tr " " "-"
    printf "-"
    printf %${SECOND_COLUMN_WIDTH}s | tr " " "-"
    printf "-"
    printf %${THIRD_COLUMN_WIDTH}s | tr " " "-"
    printf "-"
    printf %${FOURTH_COLUMN_WIDTH}s | tr " " "-"
    printf "-"
    printf %${FIFTH_COLUMN_WIDTH}s | tr " " "-"
    printf "\n"
} | tee "$SNAPSHOT_FILE"

commitBaseBlue=""
commitBaseYellow=""
commitBasePurple=""
commitBaseGreen=""
branchBlue=""
branchYellow=""
branchPurple=""
branchGreen=""

# Iterate through all directories from $ROOT_PATH
for dir in $(find $ROOT_PATH -maxdepth 1 -mindepth 1 -type d -print0 | sort -z | xargs -0); do
    # Check if the directory is a git repository
    if [ -e "$dir/.git" ]; then
        pushd "$dir" > /dev/null
        dirName=$(echo $dir | awk -F/ '{print $NF}')
        
        # Get current branch
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

        # Get the base commit
        baseCommit=$(git merge-base $baseBranch $branch)
        baseCommitDate=$(git log --format=%ad --date=short -1 $baseCommit)
        branchPointingBaseCommit=$(git branch --points-at $baseCommit)

        baseCommitSummary="$baseCommitDate, ${baseBranch:0:4}, ${baseCommit:0:7}"

        uncommittedChanges=$(git status --porcelain)

        if [[ "$uncommittedChanges" == "" || "$uncommittedChanges" == "null" || -z "$uncommittedChanges" ]]; then
            dirNameWithTags="$dirName [E]"
        else
            dirNameWithTags="$dirName [NE]"
        fi
        
        compiled=$(isRepoCompiled)
        if [[ "$compiled" == "yes" ]]; then
            dirNameWithTags="$dirNameWithTags [B]"
        else
            dirNameWithTags="$dirNameWithTags"
        fi

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

        if [[ "$dir" =~ "develA" ]]; then
            FORMAT="${formatBegin};${GREEN}m"
            commitBaseGreen="$baseCommit"
            branchGreen="$branch"
        elif [[ "$dir" =~ "develB" ]]; then
            FORMAT="${formatBegin};${BLUE}m"
            commitBaseBlue="$baseCommit"
            branchBlue="$branch"
        elif [[ "$dir" =~ "develC" ]]; then
            FORMAT="${formatBegin};${PURPLE}m"
            commitBasePurple="$baseCommit"
            branchPurple="$branch"
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
            printf "${FORMAT}%-${fst_column_width}s [%s] %s${FORMAT_END}\n" "$dirNameWithTags" "$baseCommitSummary" "$branch" | tee -a "$SNAPSHOT_FILE"
        else
            jiraStatus=$(echo "$response" | jq -r '.fields.status.name')
            printf "${FORMAT}%-${fst_column_width}s [%s] %-${THIRD_COLUMN_WIDTH}s %-${FOURTH_COLUMN_WIDTH}s %-${FIFTH_COLUMN_WIDTH}s${FORMAT_END}\n" "$dirNameWithTags" "$baseCommitSummary" "$branch" "$jiraStatus" "$summary" | tee -a "$SNAPSHOT_FILE"
        fi
        popd > /dev/null
    fi
done

exit 0

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
                elif [[ "$baseCommit" == "$commitBaseGREEN" ]]; then
                    format="\e[${NO_BOLD};${GREEN}m"
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
