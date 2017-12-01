#!/bin/bash
#
# Read users from command-line arguments.
# Add each specified user to the hub.
#

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
hub_api_token="$(${config_helper} ${config_file} JUPYTERHUB api_token)"
hub_ip="$(${config_helper} ${config_file} JUPYTERHUB hub_ip)"
api_port="$(${config_helper} ${config_file} LOAD_BALANCER api_port)"

lb="http://${hub_ip}:${api_port}"
func_rc=''

unset http_proxy
unset https_proxy

if [ $# -eq 0 ]; then
  echo "no users specified. aborting." 1>&2
  echo "usage: $0 <upi> [<upi> ...]" 1>&2
  exit 1
fi

# read users from command-line arguments
while [ $# -gt 0 ]; do
  user=$1
  shift
  echo "adding user ${user} to hub"    
  curl -s -f -X POST \
       -H "Authorization: token ${hub_api_token}" \
       -H "X-Forwarded-Remote-User: ${user}@auckland.ac.nz" \
       ${lb}/hub/api/users/${user} 
  if [ $? -eq 22 ]; then
    echo "failed to create user ${user} in jupyterhub" 1>&2 
  fi
done

