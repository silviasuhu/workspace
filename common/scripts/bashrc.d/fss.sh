#! /bin/bash

## Date:        1st of Sept 2022
## Summary:     Fss is a tool that provides an easy way to run previously defined bash commands.
## Command:     fss
##
## * How it works:
## When fss is called, a list of all the predefined commands is shown through the fzf tool and the
## user only has to select which command wants to run.
## There is the option to add arguments to the command, which will be asked through fzf as well.
##
## * How to add a new command:
## 1. Create a json file with the following structure:
## {
##     "commands": {
##         "<command_name1>": {
##             "cmd": "<command to execute>",
##             "description": "<command description with parameters surrounded by '<<' and '>>'>",
##             "parameters": {
##                 "queries": {
##                     "<query1>": {
##                         "description": "<query description>",
##                         "query_cmd": "<command to execute to get the query value>", 
##                         "element_preview": "<command to execute to get the element preview>",
##                         "default": "<default value>"
##                     },
##                     "<query2>": {
##                         ...
##                     },
##                 },
##                 "inputs": {
##                     "<input1>": {
##                         "description": "<input description>",
##                         "default": "<default value>"
##                     },
##                     "<input2>": {
##                         ...
##                     }
##                 }
##             },
##             "pre_checks": [
##                 "<pre_check1>",
##                 "<pre_check2>"
##             ]
##         },
##         "<command_name2>": {
##             ...
##         }
##     },
##     "pre_checks": {
##         "<pre_check1>": {
##             "cmd": "<command to execute>",
##             "description": "<pre check description>"
##         },
##         "<pre_check2>": {
##             "cmd": "<command to execute>",
##             "description": "<pre check description>"
##         }
##     }
## }
## Notes:
##     - A 'query' parameter will be asked to the user through fzf, the options to choose from 
##       will be the output of the "query_cmd" command
##     - An 'input' parameter will be typed by the user
##     - The "queries" section is optional
##     - The "inputs" section is optional
##     - A 'pre_check' will be executed before running the command, if it fails the command will
##       not be executed
##     - The "pre_checks" section is optional
##
## 2. Add the json file to the fss configuration file, which is located in $HOME/.fss.conf
## 3. Run fss and the new command should be available

fss() {

    CONF_FILE="$HOME/.fss.conf";

    usage() {
        echo -e "USAGE:";
        echo -e "  fss [-ph][-c <command>]"
        echo -e "";
        echo -e "OPTIONS:";
        echo -e "  -h\t\tshow this usage message";
        echo -e "  -p\t\tprint execution line without running it";
        echo -e "  -c <command>\texecute the given command";
        echo -e "";
    }

    cmdName="";
    printOnly="false";
    while getopts ":phc:" arg; do
        case $arg in
            p)
                printOnly="true";
                ;;
            h)
                usage;
                return 0;
                ;;
            c)
                cmdName=$OPTARG;
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                return 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                usage
                return 1
                ;;
        esac
    done
    shift "$((OPTIND-1))"

    commandFiles=$(__getAllCommandFilesFromConfig "$CONF_FILE");
    allCommandsFile=$(__pushAllCommandsToTmpFile "${commandFiles[@]}");

    # Ask for the command using fzf command unless it's already been given as argument
    if [ -z "$cmdName" ]; then
        cmdPreview="jq -C --tab '.commands.\"{}\"' $allCommandsFile"
        cmdName=$(jq -r '.commands | keys[]' "$allCommandsFile" | fzf --height=50% --no-multi --preview="$cmdPreview" --preview-window=right:60%:wrap ) || return

    else
        cmdExists=$(jq -r .commands."$cmdName?" "$allCommandsFile")
        if [ -z "$cmdExists" ] || [ "$cmdExists" == "null" ]; then
            echo "Command '$cmdName' not found in any commands json file";
            return 1;
        fi
    fi

    cmdJson=$(__getCommandFromJsonFile "$cmdName" "$allCommandsFile");
    cmdExec=$(echo "$cmdJson" | jq -r .cmd);

    # Execute pre_checks
    pre_checks=$(echo "$cmdJson" | jq -r '.pre_checks[]?' )
    for preCheckName in $pre_checks
    do
        preCheckJson=$(jq -r .pre_checks."$preCheckName" "$allCommandsFile")
        cmd=$(echo "$preCheckJson" | jq -r .cmd)
        description=$(echo "$preCheckJson" | jq -r .description)

        eval "$cmd"
        res=$?
        if [[ ! $res -eq 0 ]]; then
            return 1;
        fi
    done

    # Build the command

    ## Get the paramaters of type 'arg'
    args=$(echo "$cmdJson" | jq -r ".parameters.args[]?" )
    for argName in $args
    do
        arg=$(jq -r .args."$argName" "$allCommandsFile")

        description=$(echo "$arg" | jq -r .description)
        default=$(echo "$arg" | jq -r .default)
        header="select argument '$argName' for '$cmdName' command. Default: $default. Description: $description"
        arg_preview="jq -r '.args.\"${argName}\".options.\"{}\".description'  $allCommandsFile"

        value=$(echo "$arg" | jq -r '.options | keys[]' | fzf --height=50% --query="$default" --no-multi  --header="${header}" --preview="$arg_preview" --preview-window=right:60%:wrap ) || return
        cmdExec="${cmdExec//"<<$argName>>"/"$value"}"
    done


    ## Get the 'query' type paramaters
    ## A 'query' type parameter is asked to the user through fzf command, the options to choose from
    ## are given by the output of the "query_cmd" command
    queries=$(echo "$cmdJson" | jq -r '.parameters.queries? | keys? | .[]?' )
    for queryName in $queries
    do
        query=$(echo "$cmdJson" | jq -r .parameters.queries."$queryName")

        description=$(echo "$query" | jq -r .description)
        default=$(echo "$query" | jq -r .default)
        header="select argument '$queryName' for '$cmdName' command. Default: $default. Description: $description"
        query_cmd=$(echo "$query" | jq -r .query_cmd)
        elem_preview=$(echo "$query" | jq -r .element_preview)

        value=$(eval "$query_cmd" | fzf --height=50% --query="$default" --no-multi  --header="${header}" --preview="${elem_preview}" --preview-window=right:60%:wrap ) || return
        value=$(__trim "$value");
        cmdExec="${cmdExec//"<<$queryName>>"/"$value"}"
    done

    ## Get the 'input' type parameters
    ## An 'input' type parameter is typed by the user
    inputs=$(echo "$cmdJson" | jq -r ".parameters.inputs? | keys? | .[]?" )
    for inputName in $inputs
    do
        input=$(echo "$cmdJson" | jq -r .parameters.inputs."$inputName")

        description=$(echo "$input" | jq -r .description)
        defaultValue=$(echo "$input" | jq -r .default?)

        read -p "Type the '$inputName' ($description) [$defaultValue]: " value
        value=${value:-$defaultValue}
        cmdExec="${cmdExec//"<<$inputName>>"/"$value"}" 
    done

    # Add decorators to the command
    cmdBell=$(echo "$cmdJson" | jq -r .bell);
    cmdStatistics=$(echo "$cmdJson" | jq -r .statistics);

    timestampInit=$(date +%s);

    if [ "$cmdStatistics" = true ]; then
        cmdExec="reportCmdTiming $cmdExec";
    fi

    if [ "$cmdBell" = true ]; then
        cmdExec="$cmdExec; ringBellAndSetExitCode \$?;"
    fi

    if [ "$printOnly" = "true" ]; then
        echo "$cmdExec";
        history -s "$cmdExec"
        return 0;
    fi

    # Execute command
    echo "Running '$cmdExec'"
    echo ""
    history -s "$cmdExec"
    eval "$cmdExec" || return 1
}
