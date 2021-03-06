Run the services that make up the JupyterHub backend.
It includes multiple instances of JupyterHub, load-balanced by HAProxy.
All services are run in docker containers.
Notebook servers are launched on the Rancher Docker platform.
Users are pre-authenticated on the frontend Apache server through
web-SSO (shibboleth).
 
# Prerequisites:

* Set the environment variable JHUB_SETUP_DIR and point it to this directory.
* Install docker in the latest version. See doc/README_docker for tips
  about docker
* If you have not yet generated a hub api token call bin/generate_hub_api_token.sh
  and save the string printed on the screen in the variable 'api_token' in
  section 'JUPYTERHUB' in etc/config.ini
* Create HAProxy configuration file by calling bin/generate_hub_api_token.sh
  You need to do that only once.
* Adjust configuration file etc/config.ini as needed.
  In particular the following parameters need to be adjusted:
  RANCHER section: env_id, rest_base_url, access_key, secret_key 
  JUPYTERHUB section: hub_ip, api_token
* Make sure the local firewall allows connections from the frontend server
  and from the docker VMs (cows) as described in doc/README_iptables

# Start and stop services:

Launch services by e.g. calling

```
bin/manage_service.sh start nbmon hub lb
```

Stop services by e.g. calling 

```
bin/manage_service.sh stop lb hub nbmon
```

(Find out options by calling bin/manage_service.sh without any options)


# Firewall rules for the jupyterhub backend:

* The jupyterhub frontend web server must be able to connect to the backend
  on port 80
* All docker VMs (Rancher lingo: cows) must be able to connect to all hub
  ports and hub api ports (not the proxy api ports though)

See doc/README_iptables for potentially useful testing commands before
puppetising the rules 

