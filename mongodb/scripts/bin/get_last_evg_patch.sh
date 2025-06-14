EVG_BASE_URL="https://spruce.mongodb.com/patch/"
EVG_PATCHES_FILE="$HOME/.evgPatches"

usage() {
  echo "Usage: $0 [--open] [--addPRCommentWithEvgPatch] [--help|-h]"
  echo "  --open - open the last patch in the browser"
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
            usage
            exit 1
            ;;
    esac
done


NORMAL="\e[0m"
UNDERLINE_AND_GREEN="\e[4;32m"

# Get the branch name
branch=$(git rev-parse --abbrev-ref HEAD)

# Get the last patch for the current branch
lastPatch=$(grep "$branch" "$EVG_PATCHES_FILE" | tail -n 1 )
if [[ -z "$lastPatch" ]]; then
    echo "No patches found for branch: $branch"
    exit 1
fi

patchId=$(echo "$lastPatch" | cut -d ',' -f 2)
timestamp=$(echo "$lastPatch" | cut -d ',' -f 3)

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

    gh pr comment --body "$prComment"
fi

# Open the last patch in the browser
if [[ "$open" == true ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open "$EVG_BASE_URL$patchId" &> /dev/null
    elif command -v open &> /dev/null; then
        open "$EVG_BASE_URL$patchId" &> /dev/null
    else
        echo "\nNo suitable command found to open the URL."
        exit 1
    fi
    echo "\nPatch opened in browser: $EVG_BASE_URL$patchId"
fi

# Print the last patch details
printf "Evg patch: $UNDERLINE_AND_GREEN$EVG_BASE_URL$patchId$NORMAL\n"
printf "Evg timestamp: $timestamp\n"
