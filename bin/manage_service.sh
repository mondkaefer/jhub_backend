#!/bin/bash

# exit if undefined variables are used
set -u

# function to print usage
function print_usage {
  echo ""
  echo "Usage: $0 <start|stop> [lb] [hub] [nbmon]"
  echo ""
  echo "Start or stop one or more of the following services:"
  echo " * lb: load balancer (HAProxy)"
  echo " * hub: instances of JupyterHub"
  echo " * nbmon: notebook server monitor"
  echo ""
}

# function to start jupyterhub instance(s)
function start_hub {

  echo "starting jupyterhub instances"

  # read from config file
  num_hubs="$(${config_helper} ${config_file} JUPYTERHUB num_hubs)"
  hub_ip="$(${config_helper} ${config_file} JUPYTERHUB hub_ip)"
  live_hubs_base_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} JUPYTERHUB live_hubs_base_dir)"
  template_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} JUPYTERHUB template_dir)"
  ui_start_port="$(${config_helper} ${config_file} JUPYTERHUB port_range_start)"
  api_start_port="$(${config_helper} ${config_file} JUPYTERHUB api_port_range_start)"
  proxy_api_start_port="$(${config_helper} ${config_file} JUPYTERHUB proxy_api_port_range_start)"
  api_token="$(${config_helper} ${config_file} JUPYTERHUB api_token)"
  hub_label="$(${config_helper} ${config_file} JUPYTERHUB hub_label)"
  hub_docker_image="$(${config_helper} ${config_file} JUPYTERHUB docker_image)"
  cow_user_folder_dir="$(${config_helper} ${config_file} JUPYTERHUB cow_user_folder_dir)"
  notebook_server_docker_image="$(${config_helper} ${config_file} JUPYTERHUB notebook_server_docker_image)"
  container_base_name="$(${config_helper} ${config_file} JUPYTERHUB docker_container_base_name)"
  rancher_env_id="$(${config_helper} ${config_file} RANCHER env_id)"
  rancher_rest_base_url="$(${config_helper} ${config_file} RANCHER rest_base_url)"
  rancher_access_key="$(${config_helper} ${config_file} RANCHER access_key)"
  rancher_secret_key="$(${config_helper} ${config_file} RANCHER secret_key)"
  host_nbm_status_file="$(${config_helper} ${config_file} NOTEBOOK_MONITOR host_status_file)"
  container_nbm_status_file='/root/nbs_status.txt'

  let max_index=${num_hubs}-1

  for index in $(seq 0 ${max_index}); do

    hub_name="${container_base_name}$(printf %03d $index)"
    hub_dir="${live_hubs_base_dir}/${hub_name}"

    if [ ! -d "${hub_dir}" ]; then
      # create hub dir if required and copy template data over
      mkdir -p ${hub_dir}
      cp -r ${template_dir}/* ${hub_dir}

      # substitute placeholders in templates
      cfg_file=${hub_dir}/jupyterhub_config.py
      let ui_port=${ui_start_port}+${index}
      let api_port=${api_start_port}+${index}
      let proxy_api_port=${proxy_api_start_port}+${index}
      sed -i "s/__HUB_IP__/${hub_ip}/g" ${cfg_file}
      sed -i "s/__HUB_UI_PORT__/${ui_port}/g" ${cfg_file}
      sed -i "s/__HUB_API_PORT__/${api_port}/g" ${cfg_file}
      sed -i "s/__HUB_PROXY_API_PORT__/${proxy_api_port}/g" ${cfg_file}
      sed -i "s/__HUB_API_TOKEN__/${api_token}/g" ${cfg_file}
      sed -i "s/__HUB_LABEL__/${hub_label}/g" ${cfg_file}
      sed -i "s/__RANCHER_ENV_ID__/${rancher_env_id}/g" ${cfg_file}
      sed -i "s/__RANCHER_ACCESS_KEY__/${rancher_access_key}/g" ${cfg_file}
      sed -i "s/__RANCHER_SECRET_KEY__/${rancher_secret_key}/g" ${cfg_file}
      sed -i "s#__RANCHER_REST_BASE_URL__#${rancher_rest_base_url}#g" ${cfg_file}
      sed -i "s#__NOTEBOOK_DOCKER_IMAGE__#${notebook_server_docker_image}#g" ${cfg_file}
      sed -i "s#__NOTEBOOK_SERVERS_STATUS_FILE__#${container_nbm_status_file}#g" ${cfg_file}
      sed -i "s#__COW_USER_FOLDER_DIR__#${cow_user_folder_dir}#g" ${cfg_file}

      # verify all placeholders have been replaced
      count=$(grep -e '.*__[A-Za-z0-9_-].*__.*' -c ${cfg_file})
      if [ "${count}" -gt "0" ]; then
        echo 'Not all placeholders replaced in ${cfg_file}. Aborting.' 1>&2
        exit 1
      fi
    fi

    # launch hub
    let ui_port=${ui_start_port}+${index}
    let api_port=${api_start_port}+${index}
    echo "starting hub with working dir ${hub_dir}"
    docker run \
      -d \
      -p ${ui_port}:${ui_port}\
      -p ${api_port}:${api_port} \
      -v ${hub_dir}:/srv/jupyterhub \
      -v ${host_nbm_status_file}:${container_nbm_status_file} \
      --restart always \
      --net=host \
      --name ${hub_name} \
      ${hub_docker_image}

  done
}

# function to stop jupyterhub instance(s)
function stop_hub {

  echo "stopping jupyterhub instances"

  # read from config file
  num_hubs="$(${config_helper} ${config_file} JUPYTERHUB num_hubs)"
  container_base_name="$(${config_helper} ${config_file} JUPYTERHUB docker_container_base_name)"
  let max_index=${num_hubs}-1

  for index in $(seq 0 ${max_index}); do
    container_name="${container_base_name}$(printf %03d $index)"
    echo "stopping and removing ${container_name}"
    docker stop ${container_name} > /dev/null
    docker rm ${container_name} > /dev/null
  done
}

# function to start the notebook server monitor
function start_nbmon {

  echo "starting notebook monitor"

  # read from config file
  #rancher_base_url="$(${config_helper} ${config_file} RANCHER rest_base_url)"
  rancher_base_url="$(${config_helper} ${config_file} RANCHER rest_base_url_v2)"
  rancher_access_key="$(${config_helper} ${config_file} RANCHER access_key)"
  rancher_secret_key="$(${config_helper} ${config_file} RANCHER secret_key)"
  rancher_pagination_limit="$(${config_helper} ${config_file} RANCHER pagination_limit)"
  host_status_file="$(${config_helper} ${config_file} NOTEBOOK_MONITOR host_status_file)"
  host_log_file="$(${config_helper} ${config_file} NOTEBOOK_MONITOR host_log_file)"
  wait_interval_seconds="$(${config_helper} ${config_file} NOTEBOOK_MONITOR wait_interval_seconds)"
  docker_container_name="$(${config_helper} ${config_file} NOTEBOOK_MONITOR docker_container_name)"
  docker_image="$(${config_helper} ${config_file} NOTEBOOK_MONITOR docker_image)"
  container_nbm_status_file='/root/nbs_status.txt'
  container_log_file='/root/nbs_monitor.log'

  if [ ! -f "${host_status_file}" ]; then
    touch "${host_status_file}"
  fi
  if [ ! -f "${host_log_file}" ]; then
    touch "${host_log_file}"
  fi

  docker run \
    -d \
    --restart always \
    --name ${docker_container_name} \
    -e "status_file=${container_nbm_status_file}" \
    -e "log_file=${container_log_file}" \
    -e "rancher_base_url=${rancher_base_url}" \
    -e "rancher_access_key=${rancher_access_key}" \
    -e "rancher_secret_key=${rancher_secret_key}" \
    -e "rancher_pagination_limit=${rancher_pagination_limit}" \
    -e "wait_interval_seconds=${wait_interval_seconds}" \
    -v ${host_status_file}:${container_nbm_status_file} \
    -v ${host_log_file}:${container_log_file} \
    ${docker_image}
}

# function to stop the notebook server monitor
function stop_nbmon {

  echo "stopping notebook monitor"

  # read haproxy-related parameters from configuration file
  docker_container_name="$(${config_helper} ${config_file} NOTEBOOK_MONITOR docker_container_name)"

  # stop and remove docker container
  docker stop ${docker_container_name} > /dev/null
  docker rm ${docker_container_name} > /dev/null
}

# function to start load-balancer (HAProxy)
function start_lb {

  echo "starting load-balancer"

  # read haproxy-related parameters from configuration file
  base_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER base_dir)"
  mappings_dir="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER server_mappings_dir)"
  haproxy_config="${JHUB_SETUP_DIR}/$(${config_helper} ${config_file} LOAD_BALANCER config_file)"
  docker_image="$(${config_helper} ${config_file} LOAD_BALANCER docker_image)"
  docker_container_name="$(${config_helper} ${config_file} LOAD_BALANCER docker_container_name)"
  ui_port="$(${config_helper} ${config_file} LOAD_BALANCER ui_port)"
  api_port="$(${config_helper} ${config_file} LOAD_BALANCER api_port)"

  # verify haproxy configuration file exists
  if [ ! -f ${haproxy_config} ]; then
    echo " haproxy configuration file ${haproxy_config} doesn't exist. Skipping start of load-balancer"
  # verify server mappings directory exists
  elif [ ! -d ${mappings_dir} ]; then
    echo " haproxy mappings director ${mappings_dir} doesn't exist. Skipping start of load-balancer"
  else
    # launch haproxy container
    docker run -d --restart always \
      --name ${docker_container_name} \
      --net=host \
      -p ${ui_port}:${ui_port} \
      -p ${api_port}:${api_port} \
      -v ${mappings_dir}:/root/haproxy_server_mappings \
      -v ${haproxy_config}:/usr/local/etc/haproxy/haproxy.cfg:ro \
      ${docker_image} > /dev/null
  fi
}

# function to start load-balancer (HAProxy)
function stop_lb {

  echo "stopping load-balancer"

  # read haproxy-related parameters from configuration file
  docker_container_name="$(${config_helper} ${config_file} LOAD_BALANCER docker_container_name)"

  # stop and remove docker container
  docker stop ${docker_container_name} > /dev/null
  docker rm ${docker_container_name} > /dev/null
}

# verify environment variable JHUB_SETUP_DIR is set and
# points to an existing directory
if [ -z ${JHUB_SETUP_DIR+x} ] || [ ! -d "${JHUB_SETUP_DIR}" ]; then
  echo "Environment variable JHUB_SETUP_DIR is not set or points to a non-existing directory" 1>&2
  exit 1
fi

# source common functions and verify setup
source ${JHUB_SETUP_DIR}/bin/source.sh

# read, verify and process command-line parameters
if [ -z ${1+x} ]; then
  echo "Error: No operation specified. Must be 'start' or 'stop'. Aborting."
  print_usage
  exit 1
fi

if [ "$1" != "start" ] && [ "$1" != "stop" ]; then
  echo "Error: Invalid first argument: '$1'. Must be 'start' or 'stop'. Aborting."
  print_usage
  exit 1
fi

operation=$1
shift

services=''

while [[ $# -gt 0 ]]; do
  service=$1
  if [ "${service}" == "lb" ] || [ "${service}" == "hub" ] || [ "${service}" == "nbmon" ]; then
    # filter out duplicate listings of a service
    if [[ ${services} != *"${service}"* ]]; then
      services="${services} ${service}"
    fi
  else
    echo "Error: Invalid service specified: '$1'. Aborting."
    print_usage
    exit 1
  fi
  shift
done

# verify at least one service has been specified
if [ "${services}" == "" ]; then
  echo ""
  echo "Error: No valid service specified. Aborting."
  print_usage
  exit 1
fi

### start or stop specified services
for service in ${services}; do
  ${operation}_${service}
done

