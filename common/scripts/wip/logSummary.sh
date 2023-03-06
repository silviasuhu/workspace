#!/bin/bash

# Set the log file path
log_file="test.log"

# Create a new tmux pane and split the window vertically
tmux split-window -v

# Set the tmux pane to the bottom
tmux select-pane -t 1

# Start tailing the log file and print important events
tail -f $log_file | while read line; do
  if echo $line | grep -E "error|fail|critical"; then
    echo -e "\033[0;31m$line\033[0m"
  elif echo $line | grep -E "success|pass"; then
    echo -e "\033[0;32m$line\033[0m"
  fi
done
