#! /bin/bash

# Descriptions: Sync a local repository with a remote device
#

RELATIVE_REPO_PATH="devel/mongo"
REPO_PATH="$HOME/$RELATIVE_REPO_PATH"


# Parse arguments
SKIP_GIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-git)
      SKIP_GIT=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

remoteExec() {
    cmd=$1;
    echo "Running on devel-ws: $cmd"
    ssh -q -o ConnectTimeout=60 devel-ws $cmd
}

# Get the directory name of the git repository.
if [ -z "$1" ]; then
    REPO_DIR_NAME=$(basename $PWD)
else
    REPO_DIR_NAME="$1"
fi
goToRepo="cd ~/$RELATIVE_REPO_PATH/$REPO_DIR_NAME"

if [[ "$SKIP_GIT" == false ]]; then
    # Get the branch and revision to sync them later on the remote device.
    pushd "$dir" > /dev/null
    branch=$(git rev-parse --abbrev-ref HEAD)
    revision=$(git rev-parse HEAD)
    popd > /dev/null

    # Run `git checkout` to the specific branch on the remote device.
    remoteExec "$goToRepo; git checkout --quiet $branch;"

    # If checkout fails, run `git fetch` on the remote device
    if [ $? -ne 0 ]; then
        echo "git checkout failed."
        remoteExec "$goToRepo; git fetch --quiet; git checkout --quiet $branch && git reset --hard $revision"
    fi

    if [ $? -ne 0 ]; then
        echo ""
        echo "FAILURE: Checkout or reset failed. Make sure the branch has been pushed to origin"
        echo ""
        echo "To push the current branch and set the remote as upstream, use"
        echo ""
        echo "        git push --set-upstream origin $branch"
        echo ""
        exit 1
    fi
fi

# Sync all the files
echo "Running locally: rsync"
rsync --quiet -av --delete --exclude-from='.gitignore' --exclude-from=$HOME/.gitignore --exclude='.git' . devel-ws:~/$RELATIVE_REPO_PATH/$REPO_DIR_NAME/
if [ $? -ne 0 ]; then
    echo ""
    echo "FAILURE: rsync command failed."
    exit 1
fi

if [[ "$SKIP_GIT" == false ]]; then
    # Set the git repository of the remote device to the given revision.
    remoteExec "$goToRepo; git reset --soft $revision"

    # Perform a fetch if `git reset` failed.
    if [ $? -ne 0 ]; then
        echo "git reset failed."
        remoteExec "$goToRepo; git fetch --quiet; git reset --soft $revision"
    fi
    if [ $? -ne 0 ]; then
        echo ""
        echo "FAILURE: Reset failed. Make sure the branch has been pushed to origin"
        echo ""
        echo "To push the current branch and set the remote as upstream, use"
        echo ""
        echo "        git push --set-upstream origin $branch"
        echo ""
        exit 1
    fi
fi

