c.JupyterHub.authenticator_class = 'remote_user.remote_user_auth.RemoteUserAuthenticator'
c.JupyterHub.spawner_class = 'rancher.seg_spawner.RancherSpawner'
c.JupyterHub.log_level = 'DEBUG'
c.JupyterHub.debug_proxy = False
c.JupyterHub.hub_ip = '__HUB_IP__'
c.JupyterHub.port = __HUB_UI_PORT__
c.JupyterHub.hub_port = __HUB_API_PORT__
c.JupyterHub.proxy_api_port = __HUB_PROXY_API_PORT__
c.JupyterHub.cleanup_servers = False
c.JupyterHub.api_tokens = {'__HUB_API_TOKEN__':'mfel395'}
c.JupyterHub.last_activity_interval = 120
c.Authenticator.admin_users = {'mfel395'}
c.Spawner.debug = True
c.RancherSpawner.rancher_base_uri = '__RANCHER_REST_BASE_URL__'
c.RancherSpawner.rancher_access_key = '__RANCHER_ACCESS_KEY__'
c.RancherSpawner.rancher_secret_key = '__RANCHER_SECRET_KEY__'
c.RancherSpawner.jupyterhub_api_token = '__HUB_API_TOKEN__'
c.RancherSpawner.docker_image = '__NOTEBOOK_DOCKER_IMAGE__'
c.RancherSpawner.cow_user_folder_dir = '__COW_USER_FOLDER_DIR__'
c.RancherSpawner.volume_driver = 'nfs'
c.RancherSpawner.state_file = '__NOTEBOOK_SERVERS_STATUS_FILE__'
c.RancherSpawner.sleep_time_sec = 2
c.RancherSpawner.hub_label = '__HUB_LABEL__'
c.RancherSpawner.start_timeout = 60
c.RancherSpawner.http_timeout = 60
c.JupyterHub.services = [
    {
      'name': 'cull-idle',
      'admin': True,
      'command': 'python /root/src/cull_idle/cull_idle_servers.py --timeout=3600 --cull_every=300'.split(),
    }
]
#c.JupyterHub.logo_file = 'UOA-HC-RGB.png'

