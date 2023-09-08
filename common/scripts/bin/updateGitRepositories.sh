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


CONF_FILE=${1:-"$HOME/.updateGitRepositories.json"};
LOG="/tmp/updateGitRepositories.log"

echo "[$(date)][INIT] Config file: $CONF_FILE" > $LOG;

for row in $(cat ${CONF_FILE} | envsubst | jq -r '.repositories[] | @base64'); do
    repo="$(echo -n ${row} | base64 --decode --ignore-garbage)"
    echo "$repo"
    dir=$(echo $repo | jq -r .dir);
    project=$(echo $repo | jq -r .project);
    doPull=$(echo $repo | jq -r .doPull);
    doInstallVEnv=$(echo $repo | jq -r .doInstallVEnv);
    doNinjaFile=$(echo $repo | jq -r .doNinjaFile);
    doBuild=$(echo $repo | jq -r .doBuild);
    doClangdJson=$(echo $repo | jq -r .doClangdJson);

    echo "[$(date)][INIT] repo:$dir, project:$project, doPull:$doPull, doNinjaFile: $doNinjaFile, doBuild:$doBuild, doClangdJson:$doClangdJson" >> $LOG;
    
    # Pull repo
    if [[ "$doPull" = true ]]; then
        output="$(cd $dir && git pull)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo "[$(date)][ERROR][$dir][PULL] 'git pull' didn't work. $output" >> $LOG;
        else
            echo "[$(date)][INFO][$dir][PULL] 'git pull' successfully completed." >> $LOG;
        fi
    fi

    # Install virtual environment from scratch
    if [[ "$doInstallVEnv" = true ]]; then
        output="$(cd $dir && rm -r .venv; cd $dir && /opt/mongodbtoolchain/v4/bin/python3 -m venv .venv && . .venv/bin/activate && python3 -m pip install 'poetry==1.5.1' && export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring && .venv/bin/python3 -m poetry install --no-root --sync )" 
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo "[$(date)][ERROR][$dir][INSTALL-VENV] Failed installing virtual environment. $output" >> $LOG;
        else
            echo "[$(date)][INFO][$dir][INSTALL-VENV] Virtual environment installed." >> $LOG;
        fi
    fi

    # Ninja file
    if [[ "$doNinjaFile" = true ]]; then
        output="$(cd $dir && . .venv/bin/activate && buildscripts/scons.py --build-profile=fast)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo "[$(date)][ERROR][$dir][NINJA-FILE] Failed creating ninja file. $output" >> $LOG;
        else
            echo "[$(date)][INFO][$dir][NINJA-FILE] Ninja file created." >> $LOG;
        fi
    fi

    # Clangd link json
    if [[ "$doClangdJson" = true ]]; then
        output="$(cd $dir && . .venv/bin/activate && buildscripts/scons.py --build-profile=compiledb compiledb)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo "[$(date)][ERROR][$dir][CLANGD-JSON] Failed creating clangd json. $output" >> $LOG;
        else
            echo "[$(date)][INFO][$dir][CLANGD-JSON] Clangd json succeeded." >> $LOG;
        fi
    fi

    # Build
    if [[ "$doBuild" = true ]]; then
        output="$(cd $dir && ninja -j400 -f fast.ninja install-devcore)"
        res=$(echo $?);
        if [ $res -ne 0 ]; then
            echo "[$(date)][ERROR][$dir][BUILD] Build failed. $output" >> $LOG;
        else
            echo "[$(date)][INFO][$dir][BUILD] Build succeeded." >> $LOG;
        fi
    fi

done
