#!/bin/bash

# usage function
usage() {
  echo "Usage: $0 [-h] [-l <logFile>]"
  echo "  -h - prints this usage"
  echo "  -l <logFile>"
  exit 1
}

# Parse the options
while getopts ":hl:" opt; do
  case $opt in
    h)
      usage
      ;;
    l)
      logFile=$OPTARG
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

# Define the regexes
mergeableChunksQuery_regex=".*getNamespacesWithMergeableChunks took ([0-9]+) ms to get collections to merge.*"
commitTime_regex=".*Execution of MergeAllChunksOnShardCommand request completed.*elapsed: ([0-9]+).*"
commitTime_shard_regex='.*Execution of MergeAllChunksOnShardCommand request completed.*"shard":"([^"]+).*';
commitTime_nss_regex='.*Execution of MergeAllChunksOnShardCommand request completed.*"nss":"([^"]+).*';

# Create the xls files
echo -e "timestamp\tnumColls\tnumChunksPerColl\tmergeableChunksQuery(ms)" > automerger_mergeableChunksQuery.xls
echo -e "timestamp\tnumColls\tnumChunksPerColl\tcommitTime(microsec)\tshard\tnss" > automerger_commitTime.xls

numColls=0;
numChunks=0;

while read -r line; do

    if [[ $line =~ "runAutoMergerTest" ]]; then
        numColls=$(echo "$line" | sed -nE 's/.*numColls: ([0-9]+),.*/\1/p')
        numChunks=$(echo "$line" | sed -nE 's/.*numChunksPerColl: ([0-9]+).*/\1/p')
    fi

    if [[ $line =~ $mergeableChunksQuery_regex ]]; then
        timestamp=$(echo "$line" | cut -d' ' -f3)
        mergeableChunksQuery=$(echo "$line" | sed -nE "s/$mergeableChunksQuery_regex/\1/p")
        echo -e "$timestamp\t$numColls\t$numChunks\t$mergeableChunksQuery" >> automerger_mergeableChunksQuery.xls
    fi

    if [[ $line =~ $commitTime_regex ]]; then
        timestamp=$(echo "$line" | cut -d' ' -f3)
        commitTime=$(echo "$line" | sed -nE "s/$commitTime_regex/\1/p")
        shard=$(echo "$line" | sed -nE "s/$commitTime_shard_regex/\1/p")
        nss=$(echo "$line" | sed -nE "s/$commitTime_nss_regex/\1/p")
        echo -e "$timestamp\t$numColls\t$numChunks\t$commitTime\t$shard\t$nss" >> automerger_commitTime.xls
    fi

done < "$logFile"
