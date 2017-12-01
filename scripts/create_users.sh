#!/bin/bash
#
# Create all users specified in the file passed as command-line argument.
# Each line in this file must contain exactly one UPI.
# For each UPI an new mapping is created in the haproxy configuration
# and then an account is created in one of the jupyterhub instances.
# Which hub instance is used depends on the routing of the load-balancer (haproxy).
#

# Exit if undefined variables are used in this script
set -u

# Function to print usage
function print_usage {
  echo "Usage: $0 -u|--users <user list file>"
}

userlist_file=''

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

# read command-line arguments
while [[ $# -gt 1 ]]; do
  key="$1"
  case $key in
    -u|--users)
    userlist_file="$2"
    ;;
  esac
  shift
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

# call script to add user to load balancer
${base_dir}/haproxy_add_users.sh ${userlist}

# call script to create account for user in jupyterhub
${base_dir}/hub_add_users.sh ${userlist}
