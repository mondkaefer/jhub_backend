#!/bin/bash

# exit if undefined variables are used
set -u

# verify environment variable JHUB_SETUP_DIR is set and
# points to an existing directory
if [ -z ${JHUB_SETUP_DIR+x} ] || [ ! -d "${JHUB_SETUP_DIR}" ]; then
  echo "Environment variable JHUB_SETUP_DIR is not set or points to a non-existing directory" 1>&2
  exit 1
fi

# source common functions and verify setup
source ${JHUB_SETUP_DIR}/bin/source.sh

# read from config file
base_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} SCRIPTS base_dir)"

# function to print usage information
function print_usage {
  echo "Usage: $0 -u|--users <user list file>"
}

userlist_file=''

# read command-line arguments
while [[ $# -gt 1 ]]; do
  key="$1"
  case $key in
    -u|--users)
    userlist_file="$2"
    shift # past argument
    ;;
  esac
  shift # past argument or value
done

# verify command-line arguments
if [ "${userlist_file}" == "" ]; then
  echo "Error: No user list file specified"
  print_usage
  exit 1
fi

# verify userlist file exists
if [ ! -f "${userlist_file}" ]; then
  echo "Error: user list file '${userlist_file}' does not exist"
  print_usage
  exit 1
fi

# read all UPIs from userlist file into a string
userlist=$(cat ${userlist_file} | sort | uniq | tr '\n' ' ')

# call script to stop the notebook server for each user
${base_dir}/hub_stop_servers.sh ${userlist}
