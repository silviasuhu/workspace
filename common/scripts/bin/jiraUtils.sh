#!/bin/bash

# usage function
usage() {
  echo "Usage: $0 [-h] [-t <jiraTicket>] [-p]"
  printf "  -t <jiraTicket>\tjira ticket id"
  printf "  -p\tprints a jira ticket summary"
}

# Parse the options
prettyPrint=0
while getopts ":ht:p" opt; do
  case $opt in
    h)
      usage
      exit
      ;;
    t)
      jiraTicket=$OPTARG
      ;;
    p)
      prettyPrint=1
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

## Print Jira summary if -p is specified
if [ $prettyPrint -eq 1 ]; then
    pretty-print-jira-ticket()
    {
        if [ -z "$1" ]; then
            echo "Error: Jira ticket number not provided." >&2
            return 1
        fi

        # Set the Jira ticket number
        ticket=$1;

        # Get the Jira ticket information using the Jira REST API
        ticket_info=$(curl -s "https://jira.mongodb.org/rest/api/2/issue/$ticket")

        # Extract the status, summary, and description from the Jira ticket information
        status=$(echo $ticket_info | jq -r ".fields.status.name")
        summary=$(echo $ticket_info | jq -r ".fields.summary")
        description=$(echo $ticket_info | jq -r ".fields.description")

        # Print the information in a pretty format
        bold=$(tput bold)
        normal=$(tput sgr0)
        echo ""
        echo "${bold}$ticket${normal} (${bold}$status${normal})"
        echo "---------------------------------"
        echo "$summary"
        echo "---------------------------------"
        echo "$description"
        echo ""
    }

    pretty-print-jira-ticket "$jiraTicket"
fi
