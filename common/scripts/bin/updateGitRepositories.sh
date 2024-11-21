#! /bin/bash

# Date: 10th Oct 2022
# Author: Silvia Surroca
# Description: Pull and build the code of the local repositories according the 
# ~/.updateGitRepositories.json configuration file
#
# INFO PER REPO:
#     dir:
#     project:
#     doInstallVEnv: (true/false)
#     pull: (true/false)
#     build: (true/false)
#     link-json: (true/false)

# Load util_scripts.sh to use `rmBuildStamp()` and `stampSuccessfulBuild()` functions
SCRIPT_DIR=$(dirname "$0")
source $SCRIPT_DIR/../../../common/scripts/bashrc.d/util_scripts.sh

CONF_FILE=${1:-"$HOME/.updateGitRepositories.json"};

echo "[$(date)][INFO] Config file: $CONF_FILE";

# FORMAT_BOLD_AND_GREEN="\e[${BOLD};${GREEN}m"
# FORMAT_BOLD_AND_RED="\e[${BOLD};${RED}m"
FORMAT_RED="\e[0;31m"
FORMAT_GREEN="\e[0;32m"
FORMAT_END="\e[0m"

# First, perform all the pull operations since the ssh keys may expire:
echo "[$(date)][INFO] First, going to perform the pull operations for all the repos."
for row in $(cat ${CONF_FILE} | envsubst | jq -r '.repositories[] | @base64'); do
    repo="$(echo -n ${row} | base64 --decode --ignore-garbage)"
    dir=$(echo $repo | jq -r .dir);
    doPull=$(echo $repo | jq -r .doPull);

    pushd "$dir" > /dev/null

    dirname=$(basename "$dir")

    if [[ "$doPull" = true ]]; then
        echo "[$(date)][INFO][$dirname][PULL] 'git pull' started.";
        output="$(git pull &> /dev/null)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo -e "${FORMAT_RED}[$(date)][ERROR][$dirname][PULL] 'git pull' didn't work. $output${FORMAT_END}";
        else
            echo -e "${FORMAT_GREEN}[$(date)][INFO][$dirname][PULL] 'git pull' successfully completed.${FORMAT_END}";
        fi
    fi
done

# Then, perform the remaining operations:
for row in $(cat ${CONF_FILE} | envsubst | jq -r '.repositories[] | @base64'); do
    repo="$(echo -n ${row} | base64 --decode --ignore-garbage)"
    dir=$(echo $repo | jq -r .dir);
    project=$(echo $repo | jq -r .project);
    doPull=$(echo $repo | jq -r .doPull);
    doInstallVEnv=$(echo $repo | jq -r .doInstallVEnv);
    doNinjaFile=$(echo $repo | jq -r .doNinjaFile);
    doBuild=$(echo $repo | jq -r .doBuild);
    doClangdJson=$(echo $repo | jq -r .doClangdJson);

    pushd "$dir" > /dev/null

    dirname=$(basename "$dir")

    echo "[$(date)][INFO][$dirname] project:$project, doPull:$doPull, doNinjaFile: $doNinjaFile, doClangdJson:$doClangdJson, doBuild:$doBuild";

    branch=$(git rev-parse --abbrev-ref HEAD)
    branchDate=$(git log --format=%ad --date=short -1 $branch)
    echo "[$(date)][INFO][$dirname] Branch: $branch ($branchDate)."

    # Install virtual environment from scratch
    if [[ "$doInstallVEnv" = true ]]; then
        echo "[$(date)][INFO][$dirname][INSTALL-VENV] Virtual environment installation started.";

        if [[ "$project" == "mongodb-mongo-v4.4" || "$project" == "mongodb-mongo-v5.0" || "$project" == "mongodb-mongo-v6.0" || "$project" == "mongodb-mongo-v7.0" ]]; then
            output="$(rm -r .venv; /opt/mongodbtoolchain/v4/bin/python3 -m venv .venv && .venv/bin/python3 -m pip install -r buildscripts/requirements.txt --use-feature=2020-resolver &> /dev/null)" 
        else
            output="$(rm -r .venv; /opt/mongodbtoolchain/v4/bin/python3 -m venv .venv && .venv/bin/python3 -m pip install 'poetry==1.5.1' &> /dev/null && . .venv/bin/activate && ./buildscripts/poetry_sync.sh -p '.venv/bin/python3'> /dev/null)" 
        fi
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo -e "${FORMAT_RED}[$(date)][ERROR][$dirname][INSTALL-VENV] Failed installing virtual environment. $output${FORMAT_END}";
        else
            echo -e "${FORMAT_GREEN}[$(date)][INFO][$dirname][INSTALL-VENV] Virtual environment installed.${FORMAT_END}";
        fi
    fi

    # Ninja file
    if [[ "$doNinjaFile" = true ]]; then
        echo "[$(date)][INFO][$dirname][NINJA-FILE] Ninja file creation started.";

        if [[ "$project" == "mongodb-mongo-v4.4" || "$project" == "mongodb-mongo-v5.0" || "$project" == "mongodb-mongo-v6.0" ]]; then
            # Old versions command: 
            output="$(.venv/bin/python3 ./buildscripts/scons.py --variables-files=etc/scons/mongodbtoolchain_stable_clang.vars --opt=on --dbg=on --link-model=dynamic --ninja generate-ninja ICECC=icecc CCACHE=ccache &> /dev/null)"
        else
            # Newest versions can use the simpler build-profile parameter
            output="$(.venv/bin/python3 ./buildscripts/scons.py --build-profile=fast GDB_INDEX=0 &> /dev/null)"
        fi
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo -e "${FORMAT_RED}[$(date)][ERROR][$dirname][NINJA-FILE] Failed creating ninja file. $output${FORMAT_END}";
        else
            echo -e "${FORMAT_GREEN}[$(date)][INFO][$dirname][NINJA-FILE] Ninja file created.${FORMAT_END}";
        fi
    fi

    # Clangd link json
    if [[ "$doClangdJson" = true ]]; then
        echo "[$(date)][INFO][$dirname][CLANGD-JSON] Clangd json started.";
        output="$(.venv/bin/python3 ./buildscripts/scons.py --build-profile=compiledb compiledb &> /tmp/logs)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo -e "${FORMAT_RED}[$(date)][ERROR][$dirname][CLANGD-JSON] Failed creating clangd json. $output${FORMAT_END}";
        else
            echo -e "${FORMAT_GREEN}[$(date)][INFO][$dirname][CLANGD-JSON] Clangd json succeeded.${FORMAT_END}";
        fi
    fi

    # Build
    if [[ "$doBuild" = true ]]; then
        echo "[$(date)][INFO][$dirname][BUILD] Build started.";
        rmBuildStamp
        if [[ "$project" == "mongodb-mongo-v4.4" || "$project" == "mongodb-mongo-v5.0" || "$project" == "mongodb-mongo-v6.0" ]]; then
            # Old versions use the build.ninja file
            output="$(ninja -j400 -f build.ninja install-devcore &> /dev/null)"
        else
            # Newest versions use the fast.ninja file
            output="$(ninja -j400 -f fast.ninja install-devcore &> /dev/null)"
        fi
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo -e "${FORMAT_RED}[$(date)][ERROR][$dirname][BUILD] Build failed. $output.${FORMAT_END}";
        else
            stampSuccessfulBuild
            echo -e "${FORMAT_GREEN}[$(date)][INFO][$dirname][BUILD] Build succeeded.${FORMAT_END}";
        fi
    fi

    echo "[$(date)][INFO][$dirname] Finished."

    popd > /dev/null

done
