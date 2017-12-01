#!/bin/bash
#
# List all users registered on the hubs.
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
num_hubs="$(${config_helper} ${config_file} JUPYTERHUB num_hubs)"

lb="http://${hub_ip}:${api_port}"
let max_index=${num_hubs}-1

unset http_proxy
unset https_proxy

# generate api labels
haproxy_api_labels=''
for i in $(seq 0 ${max_index}); do
  api="api$(printf %03d $i)"
  haproxy_api_labels="${haproxy_api_labels} ${api}"
done

for api in ${haproxy_api_labels}; do
  echo "Users on ${api}:"
  curl -X GET \
    -H "Authorization: token ${hub_api_token}" \
    -H "Use-API: ${api}" \
    ${lb}/hub/api/users 2> /dev/null | python -m json.tool
  echo ""
done

