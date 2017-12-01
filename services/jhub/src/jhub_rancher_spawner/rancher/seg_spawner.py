import time
import requests
import json
import random
import uuid
import pyaml
from base64 import b64encode
from tornado import gen
from jupyterhub.spawner import Spawner
from traitlets import Unicode, Int

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class RancherSpawner(Spawner):

    '''A Spawner that just uses Rancher to start notebooks. Depending on the volume driver
       either no volume is mounted, and existing NFS share is mounted, or convoy-nfs is used
       to attach an NFS share to the container.
       Status of notebooks is fetched from a file rather than contacting Rancher directly.
    '''

    rancher_base_uri = Unicode(config=True)
    rancher_access_key = Unicode(config=True)
    rancher_secret_key = Unicode(config=True)
    jupyterhub_api_token = Unicode(config=True)
    docker_image = Unicode(config=True)
    volume_driver = Unicode(config=True)
    cow_user_folder_dir = Unicode(config=True)
    state_file = Unicode(config=True)
    hub_label = Unicode(config=True)
    sleep_time_sec = Int(config=True)

    def __init__(self, **kwargs):
      super(RancherSpawner, self).__init__(**kwargs)
      self.rancher_container_base_uri = '%s/containers' % self.rancher_base_uri
      userAndPass = b64encode(bytes('%s:%s'%(self.rancher_access_key, self.rancher_secret_key), 'utf-8')).decode('ascii')
      self.headers = {
        'Authorization': 'Basic %s' % userAndPass,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }

    def load_state(self, state):
      '''load service id from state'''
      super(RancherSpawner, self).load_state(state)
      if 'cid' in state:
        self.cid = state['cid']
    
    def get_state(self):
      '''add service id to state'''
      state = super(RancherSpawner, self).get_state()
      if self.cid:
        state['cid'] = self.cid
      return state
    
    def clear_state(self):
      '''clear service id state'''
      super(RancherSpawner, self).clear_state()
      self.cid = 0

    @gen.coroutine
    def _get_container_info(self):
      if not self.cid:
        raise Exception('container id not available')
      attempt=0
      max_attempts=6
      return_lines = []
      while attempt < max_attempts:
        lines = [ line.rstrip('\n') for line in open(self.state_file) ]
        return_lines = [ line for line in lines if line.startswith(self.cid) ]
        if not return_lines or len(return_lines) == 0:
          msg = 'no information for notebook for user %s (attempt %s)' % (self.user.name, attempt)
          self.log.warn(msg)
          time.sleep(0.5)
          attempt += 1
        else:
          break
      return return_lines

    @gen.coroutine
    def _wait_for_endpoint(self, max_attempts=30):
      self.log.debug('----- waiting for endpoint for user %s' % self.user.name)
      count = 1
      try:
        while count <= max_attempts:
          lines = yield self._get_container_info()
          if lines:
            line = lines[0]
            endpoint = line.split('|')[3]
            if endpoint.split(':') and len(endpoint.split(':')) == 2:
              self.log.debug ('----- done waiting for endpoint for user %s: %s' % (self.user.name, endpoint))
              return (endpoint.split(':')[0], endpoint.split(':')[1])
          time.sleep(1)
          count += 1
      except:
        raise
      raise Exception('Notebook not in state %s after 10 attempts.' % state)

    @gen.coroutine
    def start_container(self, json_payload):
      self.log.debug('----- calling rancher to start container for %s' % self.user.name)
      response = requests.post(self.rancher_container_base_uri, data=json_payload, headers=self.headers, verify=False)
      self.log.debug('----- done calling rancher to start container for %s' % self.user.name)
      return response

    @gen.coroutine
    def start(self):
      '''Start notebook'''
      self.log.debug('--- starting container for user %s' % self.user.name)
      self.log.debug("self.user.server.base_url: %s" % self.user.server.base_url)
      self.log.debug("self.hub.api_url: %s" % self.hub.api_url)
      self.log.debug("dict returned by get_args(): %s" % str(self.get_args()))

      body = {
        'expose': [],
        'imageUuid': 'docker:%s' % self.docker_image,
        'name': "%s-%s" % (self.user.name, str(uuid.uuid4())),
        'networkIds': [],
        'ports': ['8888/tcp'],
        'startOnCreate': True,
        'command': [ 'start-singleuser.sh' ],
        'publishAllPorts': False,
        'privileged': False,
        'stdinOpen': True,
        'tty':True,
        'entryPoint':[],
        'extraHosts':[],
        'readOnly':False,
        'build': None,
        'networkMode': 'managed',
        'memory': 500000000,
        'dataVolumesFrom': [],
        'environment': {
          'JPY_API_TOKEN': '%s' % self.jupyterhub_api_token,
          'JPY_BASE_URL': '%s' % self.user.server.base_url,
          'JPY_COOKIE_NAME': '%s' % self.user.server.cookie_name,
          'JPY_HUB_API_URL': '%s' % self.hub.api_url,
          'JPY_USER': '%s' % self.user.name,
          'JPY_HUB_PREFIX': '/hub/'
        },
        'labels': {
          'hub_label': '%s' % self.hub_label
        } 
      }

      if self.volume_driver == 'convoy-nfs':
        body['volumeDriver'] = self.volume_driver
        body['dataVolumes'] = [ '%s:/home/jovyan' % self.user.name ]
      elif self.volume_driver == 'nfs':
        if not self.cow_user_folder_dir:
          self.log.error('nfs as volume driver specified, but no cow_user_folder_dir configured - no volume will be mounted')
        else:
          body['dataVolumes'] = [ '%s/%s:/home/jovyan' % (self.cow_user_folder_dir, self.user.name) ]

      json_payload = json.dumps(body)
      response = yield self.start_container(json_payload)
      status_code = int(response.status_code)
      if status_code >= 400:
        raise Exception('Failed to spawn notebook stack: %s' % response.text)
      json_body = json.loads(response.text)
      self.cid = json_body['id']
      self.user.server.ip, self.user.server.port = yield self._wait_for_endpoint()
      self.log.info("notebook environment was started for {}  ({}:{})".format(
        self.user.name, self.user.server.ip, self.user.server.port))
      # self.db.commit()
      self.log.debug('--- done starting container for user %s' % self.user.name)
      return (self.user.server.ip, self.user.server.port)

    @gen.coroutine
    def poll(self):
      '''poll notebook'''
      self.log.info('poll called for user {}'.format(self.user.name))
      try:
        lines = yield self._get_container_info() 
        if lines[0].split('|')[2] == 'running':
          self.log.debug('poll returned {}'.format('None'))
          return None
        else:
          self.log.debug('poll returned {}'.format(1))
          return 1
      except:
        self.log.debug('poll returned {}'.format(2))
        return 2
 
    @gen.coroutine
    def stop(self, now=False):
      '''stop notebook'''
      
      self.log.info('stop now = {}'.format(now))
      if not self.cid:
        raise Exception('container id not available') 
      url = '%s/%s' % (self.rancher_container_base_uri, self.cid)
      response = requests.delete(url, headers=self.headers, verify=False)
      status_code = int(response.status_code)
      if status_code >= 400:
        raise Exception('Failed to shut down notebook stack: %s' % response.text)

