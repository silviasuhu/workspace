#! /bin/bash

# This script is used to process the config.chunks of a MongoDB database

# usage function
usage() {
  echo "Usage: $0 [-h] [-p/-c] [-u <collUUID>] <chunks.bson>"
  echo "  -h - prints this usage"
  echo "  -u <collUUID> - filter chunks by collection UUID"
  echo "  -c - checks consistency of the chunks"
  echo "  -p - prints all the chunks sorted by min field"
  exit 1
}


# Define the options
options=":hcpu:"

checkConsistency=0
printChunks=0
# Parse the options
while getopts "$options" opt; do
  case $opt in
    h)
      usage
      ;;
    u)
      uuid=$OPTARG
      ;;
    c)
        checkConsistency=1
        ;;
    p)
        printChunks=1
        ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done

# Remove the parsed options
shift $((OPTIND-1))

# Check if there's a filename left
if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

# Get the filename
chunksBsonFile=$1

# Check if the file exists
if [ ! -f "$chunksBsonFile" ]; then
  echo "Error: $chunksBsonFile not found."
  exit 1
fi

# Check consistency of chunks
# Consistency means that for every chunk should exist another chunk where its max field is equal to the min field of the current chunk
if [ "$checkConsistency" -eq 1 ]; then
    if [ -z "$uuid" ]; then
    jqQuery='[inputs]'
    else
    jqQuery='[inputs] | map(select( ."uuid"."$binary"."base64" == "'$uuid'" ))'
    fi
    jqQuery="$jqQuery | sort_by(.min) | .[] | {shard, min, max}"

    bsondump $chunksBsonFile | jq -cr "$jqQuery" | while read -r chunk; do
        shard=$(echo $chunk | jq -r '.shard')
        min=$(echo $chunk | jq -r '.min')
        max=$(echo $chunk | jq -r '.max')

        # check if there's a chunk with the same shard and max field
        bsondump $chunksBsonFile | jq -cr "$jqQuery" | grep -q "\"min\":$max"
        if [ "$?" -ne 0 ]; then
            echo "Error: chunk with shard $shard and min $max not found"
            exit 1
        fi
    done
    exit 0
fi

# Print chunks sorted by min field
if [ "$printChunks" -eq 1 ]; then
    if [ -z "$uuid" ]; then
    jqQuery='[inputs]'
    else
    jqQuery='[inputs] | map(select( ."uuid"."$binary"."base64" == "'$uuid'" ))'
    fi
    jqQuery="$jqQuery | sort_by(.min) | .[] | {shard, min, max}"

    bsondump $chunksBsonFile | jq -cr "$jqQuery"
    exit 0
fi

# Exit successfully
exit 0
