#!/bin/bash

config_helper="${JHUB_SETUP_DIR}/bin/config_get"
config_file="${JHUB_SETUP_DIR}/etc/config.ini"

function exit_error {
  echo "Error: $@" 1>&2
  exit 1
}

# verify setup 

if [ ! -d "${JHUB_SETUP_DIR}" ]; then
  exit_error "Directory pointed to by env var JHUB_SETUP_DIR (${JHUB_SETUP_DIR}) does not exist"
fi

if [ ! -f "${config_file}" ]; then
  exit_error "Configuration file ${config_file} doesn't exist"
fi

if [ ! -x ${config_helper} ]; then
  exit_error "Helper script ${config_helper} doesn't exist or is not executable"
fi 

