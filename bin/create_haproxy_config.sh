#!/bin/bash
#
# use haproxy configuration templates and central configuration file
# to create haproxy (load-balancer for jupyterhub instances) 
# configuration file
#

# exit if undefined variables are used
set -u

# function to print usage
function print_usage {
  echo "Usage: $0 [-f|--force] [-h|--help] "
}

# verify environment variable JHUB_SETUP_DIR is set and
# points to an existing directory
if [ -z ${JHUB_SETUP_DIR+x} ] || [ ! -d "${JHUB_SETUP_DIR}" ]; then
  echo "Environment variable JHUB_SETUP_DIR is not set or points to a non-existing directory" 1>&2
  exit 1
fi

# source common functions and verify setup
source ${JHUB_SETUP_DIR}/bin/source.sh

# variable definitions. most of the values are read from the
# central configuration file
lb_ui_port="$(${config_helper} ${config_file} LOAD_BALANCER ui_port)"
lb_api_port="$(${config_helper} ${config_file} LOAD_BALANCER api_port)"
num_hubs="$(${config_helper} ${config_file} JUPYTERHUB num_hubs)"
lb_base_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER base_dir)"
template_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER template_dir)"
mappings_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER server_mappings_dir)"
haproxy_config_file="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER config_file)"
hub_ip="$(${config_helper} ${config_file} JUPYTERHUB hub_ip)"
ui_port_range_start="$(${config_helper} ${config_file} JUPYTERHUB port_range_start)"
api_port_range_start="$(${config_helper} ${config_file} JUPYTERHUB api_port_range_start)"

# only overwrite configuration file if explicitely wanted
# read command-line parameters
overwrite=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      overwrite=1
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
  esac
  shift # past argument or value
done

# create configuration directory if it doesn't yet exist
config_dir=$(dirname ${haproxy_config_file})
if [ ! -d "${config_dir}" ]; then
  mkdir -p "${config_dir}"
fi

# check if configuration file already exists
if [ -f "${haproxy_config_file}" ] && [ "${overwrite}" -eq 0 ] ; then
  echo "Configuration file ${haproxy_config_file} already exists. Use the -f option to overwrite" 1>&2
  print_usage
  exit 1
fi

# create user2server mapping directory if it doesn't yet exist
if [ ! -d "${mappings_dir}" ]; then
  mkdir ${mappings_dir}
fi

# start from 0
let num_hubs=num_hubs-1

# start with base configuration
cat ${template_dir}/base.tpl > "${haproxy_config_file}"

# create ui frontent
cat ${template_dir}/ui_frontend.tpl | sed "s/__UI_PORT__/${lb_ui_port}/g" >> "${haproxy_config_file}"
for i in $(seq 0 ${num_hubs}); do
  hub_id="hub$(printf %03d $i)"
  mapping_file=${hub_id}.lst
  cat ${template_dir}/ui_use_backend.tpl | \
    sed "s/__UI_ID__/${hub_id}/g" | \
    sed "s#__MAPPING_FILE__#${mapping_file}#g" >> "${haproxy_config_file}"
  if [ ! -f "${mappings_dir}/${mapping_file}" ]; then
    touch "${mappings_dir}/${mapping_file}"
  fi
done

# create api frontend
echo "" >> "${haproxy_config_file}"
cat ${template_dir}/api_frontend.tpl | sed "s/__API_PORT__/${lb_api_port}/g" >> "${haproxy_config_file}"
for i in $(seq 0 ${num_hubs}); do
  hub_id="hub$(printf %03d $i)"
  api_id="api$(printf %03d $i)"
  mapping_file=${hub_id}.lst
  cat ${template_dir}/api_use_backend.tpl | \
    sed "s/__API_ID__/${api_id}/g" | \
    sed "s#__MAPPING_FILE__#${mapping_file}#g" >> "${haproxy_config_file}"
done

# create ui backends
echo "" >> "${haproxy_config_file}"
echo "# ui backends" >> "${haproxy_config_file}"
port=${ui_port_range_start}
for i in $(seq 0 ${num_hubs}); do
  hub_id="hub$(printf %03d $i)"
  cat ${template_dir}/ui_backend.tpl | \
    sed "s/__UI_ID__/${hub_id}/g" | \
    sed "s/__HUB_IP__/${hub_ip}/g" | \
    sed "s/__UI_PORT__/${port}/g" >> "${haproxy_config_file}"
  let port=port+1
done

# create api backends
echo "# api backends" >> "${haproxy_config_file}"
port=${api_port_range_start}
for i in $(seq 0 ${num_hubs}); do
  api_id="api$(printf %03d $i)"
  cat ${template_dir}/api_backend.tpl | \
    sed "s/__API_ID__/${api_id}/g" | \
    sed "s/__HUB_IP__/${hub_ip}/g" | \
    sed "s/__API_PORT__/${port}/g" >> "${haproxy_config_file}"
  let port=port+1
done

