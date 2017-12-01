#!/bin/bash
#
# Read users from command-line arguments.
# Add each user to the haproxy server mapping file with the least number of users.
# Reload haproxy.
#

# exit if undefined variables are used in this script
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
haproxy_map_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER server_mappings_dir)"
haproxy_docker_container_name="$(${config_helper} ${config_file} LOAD_BALANCER docker_container_name)"

func_rc=''

#
# check if user already exists in haproxy mapping files
# return 0 if user doesn't exist and 1 if user exists
#
function check_user_exists_in_haproxy {
  user=$1
  $(cat ${haproxy_map_dir}/* | grep -e "^${user}@auckland.ac.nz$" 1>/dev/null 2>/dev/null)
  if [ "$?" -gt "0" ]; then
    # user doesn't exist
    func_res=0
  else
    func_res=1
  fi
}

#### main program

# verify at least one UPI has been specified as command-line argument
if [ $# -eq 0 ]; then
  echo "No users specified. Aborting." 1>&2
  echo "Usage: $0 <upi> [<upi> ...]" 1>&2
  exit 1
fi

# verify haproxy map directory exist
if [ ! -d "${haproxy_map_dir}" ]; then
  echo "HAProxy map directory '${haproxy_map_dir} doesn't exist. Aborting." 1>&2
  exit 1
fi

users=''

# read users from command-line arguments
while [ $# -gt 0 ]; do
  user=$1
  shift

  # verify user isn't already listed in the map files
  check_user_exists_in_haproxy ${user}
  if [ $func_res -gt 0 ]; then
    echo "User ${user} already listed in one of the haproxy map files. ignoring." 1>&2
    continue
  fi

  # get the map file with the lowest number of users in it
  map_file=$(wc -l ${haproxy_map_dir}/* 2> /dev/null | sed -e 's/^[ \t]*//' | head -n -1 | sort -n | head -n 1 | cut -d\  -f 2 2>/dev/null)

  if [ "${map_file}" == "" ]; then
    echo "no haproxy map file found. aborting" 1>&2
    exit 1
  else
    # append user to map file, reload haproxy, create user in jupyterhub
    echo "adding user ${user} to haproxy"
    echo "${user}@auckland.ac.nz" >> ${map_file}
  fi
done    

# have haproxy reload the user mapping files
echo "Reloading HAProxy..."
docker kill -s HUP ${haproxy_docker_container_name} > /dev/null

