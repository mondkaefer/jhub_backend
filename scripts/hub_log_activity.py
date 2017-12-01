import os
import json
import requests
import calendar
from datetime import datetime, timedelta

log_file = '/root/hub_activity.log'
url = 'http://jhub-backend.engineering.auckland.ac.nz:8080/hub/api/users'
hub_api_token = '7KYlgyH4C6ESGoX07DeeFsvCTMdCH0'
haproxy_api_labels = [ 'api00', 'api01', 'api02', 'api03', 'api04' ]
users = {}

def utc_to_local(utc_dt):
    # get integer timestamp to avoid precision lost
    timestamp = calendar.timegm(utc_dt.timetuple())
    local_dt = datetime.fromtimestamp(timestamp)
    assert utc_dt.resolution >= timedelta(microseconds=1)
    return local_dt.replace(microsecond=utc_dt.microsecond)

# loop over all api labels
for api_label in haproxy_api_labels:
  headers = {
    'Authorization': 'token %s' % hub_api_token,
    'Use-API': api_label
  }
  r = requests.get(url, headers=headers)
  d = json.loads(r.text)
  # loop over all users
  for entry in d:
    dt = datetime.strptime(entry['last_activity'], "%Y-%m-%dT%H:%M:%S.%f")
    upi = entry['name']
    if upi in users:
      if dt > users[upi]:
        users[upi] = utc_to_local(dt)
    else:
      users[upi] = utc_to_local(dt)

# create log file if doesn't yet exist
if not os.path.isfile(log_file):
  with open(log_file, 'w') as f:
    pass

# read already existing entries
with open(log_file, 'r') as f:
  lines = f.read().splitlines()

# add new log entries
for upi in sorted(users.keys()):
  log_entry = '%s: %s' % (upi, users[upi])
  if log_entry not in lines:
    with open(log_file, 'a') as f:    
      f.write('%s%s' % (log_entry, os.linesep))
