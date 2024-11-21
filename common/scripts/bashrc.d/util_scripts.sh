## Date:        1st of November 2022
## Description: 

reportCmdTiming()
{
    timestampInit=$(date +%s);
    dateInit=$(date);
    echo "Started '$dateInit'";
    
    eval $@;
    res=$?;

    echo "reportCmdTiming REPORT:"
    echo "    Started '$dateInit'";
    echo "    Finished '$(date)'";
    timestampEnd=$(date +%s);
    echo "    Elapsed $(expr $timestampEnd - $timestampInit) seconds.";
    echo "    Result: $res";

    return $res;
}

ringBellAndSetExitCode()
{
    tput bel;
    res=${1:-1};
    return $res;
}

# Returns a unique string to identify the current repository status.
# This string is composed by:
#     - The last commit hash (git log -n 1 --format=%H)
#     - Followed by the md5 of the (git diff) command
getRepoMd5()
{
    commitHash=$(git log -n 1 --format=%H)
    uncommittedChangesMd5=$(git diff | md5sum)
    echo "$commitHash$uncommittedChangesMd5"
}

stampSuccessfulBuild()
{
    md5=$(getRepoMd5)
    echo "$md5" > .lastCompilationMd5
}

rmBuildStamp()
{
    if [[ -f .lastCompilationMd5 ]]; then
        rm .lastCompilationMd5
    fi
}

isRepoCompiled()
{
    if [[ -f .lastCompilationMd5 ]]; then
        md5=$(getRepoMd5)
        lastCompilationMd5=$(cat .lastCompilationMd5)
        if [[ "$lastCompilationMd5" == "$md5" ]]; then
            echo "yes"
        else
            echo "no"
        fi
    else
        echo "no"
    fi
}


