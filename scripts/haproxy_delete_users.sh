#!/bin/bash
#
# Read users from command-line arguments.
# Delete each user from the haproxy server mapping files.
# Reload haproxy.
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
haproxy_map_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER server_mappings_dir)"
haproxy_docker_container_name="$(${config_helper} ${config_file} LOAD_BALANCER docker_container_name)"

func_rc=''

# verify at least one UPI has been specified as command-line argument
if [ $# -eq 0 ]; then
  echo "No users specified. Aborting." 1>&2
  echo "Usage: $0 <upi> [<upi> ...]" 1>&2
  exit 1
fi

# verify haproxy map directory exist
if [ ! -d "${haproxy_map_dir}" ]; then
  echo "HAProxy map directory '${haproxy_map_dir} doesn't exist. Aborting" 1>&2
  exit 1
fi

maps=$(ls ${haproxy_map_dir})

# read users from command-line arguments
while [ $# -gt 0 ]; do
  user=$1
  shift
  echo "Deleting user ${user} from haproxy"
  for map in ${maps}; do
    m=${haproxy_map_dir}/${map}
    tmpfile=$(mktemp)
    cat ${m} | grep -v -e "^${user}@auckland.ac.nz$" > ${tmpfile}
    cat ${tmpfile} > ${m}
    rm -f ${tmpfile}
  done
done

# reload haproxy 
echo "Reloading HAProxy..."
docker kill -s HUP ${haproxy_docker_container_name} > /dev/null

