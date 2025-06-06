EVG_BASE_URL="https://spruce.mongodb.com/patch/"
EVG_PATCHES_FILE="$HOME/.evgPatches"

NORMAL="\e[0m"
UNDERLINE_AND_GREEN="\e[4;32m"

# Get the branch name
branch=$(git rev-parse --abbrev-ref HEAD)

# Get the last patch for the current branch
lastPatch=$(grep "$branch" "$EVG_PATCHES_FILE" | tail -n 1 )

patchId=$(echo "$lastPatch" | cut -d ',' -f 2)
timestamp=$(echo "$lastPatch" | cut -d ',' -f 3)

if [[ -z "$lastPatch" ]]; then
    echo "No patches found for branch: $branch"
    exit 1
else
    printf "\n"
    printf "$timestamp\n"
    printf "$UNDERLINE_AND_GREEN$EVG_BASE_URL$patchId$NORMAL\n\n"
fi