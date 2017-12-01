#!/bin/bash
#
# Tiny wrapper around monitor.py to have it run periodically and log to logfile
#

if [ -z ${log_file+x} ]; then
  echo >&2 "Environment variable 'log_file' is not set. Aborting."
  exit 1
fi

if [ -z ${wait_interval_seconds+x} ]; then
  echo >&2 "Environment variable 'wait_interval_seconds' is not set. Aborting."
  exit 1
fi

# verify python3 is installed and on search path
python3 -V >/dev/null 2>&1 || { echo >&2 "python3 is not installed or not in search path. aborting."; exit 1; }

while [ 1 == 1 ]; do
  msg=$(python3 monitor.py 2>&1)
  if [ "$?" -gt "0" ]; then
    ts="$(date +'%Y-%m-%d %H:%M:%S')"
    echo "${ts} ERROR $msg" >> ${log_file}
  fi
  sleep ${wait_interval_seconds}
done

