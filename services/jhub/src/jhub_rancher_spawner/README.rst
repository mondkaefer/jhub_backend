==========================
Jupyterhub Rancher Spawner
==========================

A spawner that just uses Rancher to start notebooks in docker containers.
Depending on the volume driver either no volume is mounted, and existing NFS
share is mounted, or convoy-nfs is used to attach a share of an NFS to the
notebook containers. If nfs or convoy-nfs are used as volume driver, the 
volume will be mounted in the container on the notebook directory.

------------
Installation
------------

This package can be installed with `pip`::

    cd jhub_rancher_spawner
    pip3 install -U -r requirements.txt .

Alternately, you can add the rancher folder to your PYTHONPATH. Note, that you
have to install the dependencies listed in requirements.txt separately then.

-------------
Configuration
-------------

To configure the Rancher spawner add the following to your JupyterHub configuration file
(default jupyterhub_config.py) and adjust the values as needed::

    c.JupyterHub.spawner_class = 'rancher.spawner.RancherSpawner'
    c.JupyterHub.hub_ip = '<IP-ADDRESS OF JUPYTERHUB>'
    c.Spawner.debug = True
    c.RancherSpawner.rancher_base_uri = 'https://rancher.container.auckland.ac.nz/v1/projects/<YOUR_PROJECT_ID>'
    c.RancherSpawner.rancher_access_key = '<YOUR_PROJECT_ACCESS_KEY>'
    c.RancherSpawner.rancher_secret_key = '<YOUR_PROJECT_SECRET_KEY>'
    c.RancherSpawner.jupyterhub_api_token = '<JUPYTERHUB API TOKEN>'
    c.RancherSpawner.docker_image = '<DOCKER IMAGE TO BE USED>'
    c.RancherSpawner.volume_driver = '[convoy-nfs|nfs]'
    c.RancherSpawner.sleep_time_sec = 2


If nfs is used as volume driver add the mount point where the share is mounted on the cows::

    c.RancherSpawner.cow_user_folder_dir = '<MOUNTPOINT OF NFS SHARE>'


Restart JupyterHub to activate the changes.

Example configurations:

a) Using no volume driver::

    c.JupyterHub.spawner_class = 'rancher.spawner.RancherSpawner'
    c.JupyterHub.hub_ip = '130.216.161.193'
    c.JupyterHub.log_level = 'DEBUG'
    c.Spawner.debug = True
    c.RancherSpawner.rancher_base_uri = 'https://rancher.container.auckland.ac.nz/v1/projects/1a3354'
    c.RancherSpawner.rancher_access_key = '645AB3CE5212191C9BA2'
    c.RancherSpawner.rancher_secret_key = 'v5gi9eTL2F7aCaG9bbA4FQQEWhSZ5Pnn3jiff9Nz'
    c.RancherSpawner.jupyterhub_api_token = 'afab7374668f44da92b3d5bc48e7c814'
    c.RancherSpawner.docker_image = 'registry.dev.container.auckland.ac.nz:5000/mfel395/jhub-test-notebook'
    c.RancherSpawner.sleep_time_sec = 2

b) Using convoy-nfs::

    c.JupyterHub.spawner_class = 'rancher.spawner.RancherSpawner'
    c.JupyterHub.hub_ip = '130.216.161.193'
    c.JupyterHub.log_level = 'DEBUG'
    c.Spawner.debug = True
    c.RancherSpawner.rancher_base_uri = 'https://rancher.container.auckland.ac.nz/v1/projects/1a3354'
    c.RancherSpawner.rancher_access_key = '645AB3CE5212191C9BA2'
    c.RancherSpawner.rancher_secret_key = 'v5gi9eTL2F7aCaG9bbA4FQQEWhSZ5Pnn3jiff9Nz'
    c.RancherSpawner.jupyterhub_api_token = 'afab7374668f44da92b3d5bc48e7c814'
    c.RancherSpawner.docker_image = 'registry.dev.container.auckland.ac.nz:5000/mfel395/jhub-test-notebook'
    c.RancherSpawner.volume_driver = 'convoy-nfs'
    c.RancherSpawner.sleep_time_sec = 2

c) Using nfs::

    c.JupyterHub.spawner_class = 'rancher.spawner.RancherSpawner'
    c.JupyterHub.hub_ip = '130.216.161.193'
    c.JupyterHub.log_level = 'DEBUG'
    c.Spawner.debug = True
    c.RancherSpawner.rancher_base_uri = 'https://rancher.container.auckland.ac.nz/v1/projects/1a3354'
    c.RancherSpawner.rancher_access_key = '645AB3CE5212191C9BA2'
    c.RancherSpawner.rancher_secret_key = 'v5gi9eTL2F7aCaG9bbA4FQQEWhSZ5Pnn3jiff9Nz'
    c.RancherSpawner.jupyterhub_api_token = 'afab7374668f44da92b3d5bc48e7c814'
    c.RancherSpawner.docker_image = 'registry.dev.container.auckland.ac.nz:5000/mfel395/jhub-test-notebook'
    c.RancherSpawner.volume_driver = 'nfs'
    c.RancherSpawner.cow_user_folder_dir = '/share'
    c.RancherSpawner.sleep_time_sec = 2   
