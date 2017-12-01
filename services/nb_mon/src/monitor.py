import os
import sys
import json
import logging
import argparse
import requests
import traceback
from os import environ as env
from base64 import b64encode

# disable ssl-related warnings 
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# verify required environment variables are set
if not 'rancher_base_url' in env:
  print ('Environment variable rancher_base_url not set. Aborting')
  sys.exit(1)
elif not 'rancher_access_key' in env:
  print ('Environment variable rancher_access_key not set. Aborting')
  sys.exit(1)
elif not 'rancher_secret_key' in env:
  print ('Environment variable rancher_secret_key not set. Aborting')
  sys.exit(1)
elif not 'rancher_pagination_limit' in env:
  print ('Environment variable rancher_pagination_limit not set. Aborting')
  sys.exit(1)
elif not 'status_file' in env:
  print ('Environment variable status_file not set. Aborting')
  sys.exit(1)
  
# variable definitions
hosts_url = '%s/hosts?limit=%s' % (env['rancher_base_url'], env['rancher_pagination_limit'])
url = '%s/containers?limit=%s' % (env['rancher_base_url'], env['rancher_pagination_limit'])
userpass = '%s:%s' % (env['rancher_access_key'], env['rancher_secret_key'])
encoded_userpass = b64encode(bytearray(userpass, encoding='utf-8')).decode('ascii')
status_file = env['status_file']
timeout_sec = 2
http_headers = {
  'Authorization': 'Basic %s' % encoded_userpass,
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

# get hosts from Rancher API
# TODO: handle paging
try:
  response = requests.get(hosts_url, headers=http_headers, verify=False, timeout=timeout_sec)
except requests.exceptions.ConnectTimeout:
  print('Connection timeout to %s after %s seconds. Skipping' % (hosts_url, timeout_sec))
  sys.exit(1)
except:
  print('An error occured when connecting to %s' % (url))
  sys.exit(1)

status_code = int(response.status_code)
if status_code >= 400:
  print('Received status code %s from Rancher API. Error message: %s' % (status_code, response.text))
  sys.exit(1)

hostdict={}

# process received JSON data
try:
  hostlist = json.loads(response.text)['data']
  for host in hostlist:
    hostdict[host['id']] = host['agentIpAddress']
except:
  print('Failed to deserialize json when getting host list.')
  sys.exit(1)


# get container information from Rancher API
# TODO: handle paging
try:
  response = requests.get(url, headers=http_headers, verify=False, timeout=timeout_sec)
except requests.exceptions.ConnectTimeout:
  print('Connection timeout to %s after %s seconds. Skipping' % (url, timeout_sec))
  sys.exit(1)
except:
  print('An error occured when connecting to %s' % (url))
  sys.exit(1)
 
status_code = int(response.status_code)
if status_code >= 400:
  print('Received status code %s from Rancher API. Error message: %s' % (status_code, response.text))
  sys.exit(1)

# process received JSON data
try:
  result = json.loads(response.text)
except:
  print('Failed to deserialize json when getting container list.')
  sys.exit(1)

try:
  containers = {}
  if 'data' in result:
    data = result['data']
    for d in data:
     containerId = d['id']
     if 'environment' in d:
       env = d['environment']
       if env and 'JPY_USER' in env:
         tmpdict = {'user': env['JPY_USER']}
         tmpdict['state'] = d['state']
         if 'ports' in d and len(d['ports']) > 0 and len(d['ports'][0].split(':')) == 3:
           # TODO: verify host is in dict
           tmpdict['endpoint'] = '%s:%s' % (hostdict[d['hostId']], d['ports'][0].split(':')[1])
         else:
           tmpdict['endpoint'] = ''
         containers[containerId] = tmpdict
  else:
    raise Exception('Internal error: no "data" element in dict')
except:
  print('Failed to convert data.')
  raise
  sys.exit(1)

# write results to file
try:
  with open(status_file, "w") as f:
    for containerId in containers.keys():
      container = containers[containerId]
      f.write('%s|%s|%s|%s%s' % (containerId, container['user'], container['state'], container['endpoint'], os.linesep))
except:
  print('Failed to write data to file %s.' % status_file)
  sys.exit(1)

