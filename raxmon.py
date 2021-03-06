#!/usr/bin/python
import requests, json, time, logging

logging.basicConfig(filename='/var/log/raxmon.log', format='%(asctime)s %(message)s', level=logging.INFO)

# On client machine execute:
# apt-get install python-pip
# pip install requests

SLEEP_TIME = 20

# define program-wide variables
TENANT_NAME = 'admin'
USERNAME = 'admin'
PASSWORD = 'Hc3RceSQ'

KEYSTONE_ADMIN_ADDRESS = '172.24.240.93'
KEYSTONE_ADMIN_PORT = '5000'


# REST resource for BIG-IP that all other requests will use
raxmon = requests.session()
raxmon.verify = False
raxmon.headers.update({'Content-Type' : 'application/json'})


def test_keystone_service(raxmon, tenant_name, username, password, address, port):
    payload = {}

    # define test pool
    payload = {"auth": {"tenantName": tenant_name, "passwordCredentials": {"username": username, "password": password}}}

    RAXMON_URL_BASE = 'http://%s:%s' % (address,port)
    r = raxmon.post('%s/v2.0/tokens' % RAXMON_URL_BASE, data=json.dumps(payload))
    print r.status_code
    #print json.loads(data)["access"]["token"]["id"]
    tenantid = json.loads(r.text)["access"]["token"]["id"]
    logging.info('[keystone_admin] %s', r.status_code)
    return tenantid
    
# Test keystone service using 'keystone tenant-list'
tenantid = test_keystone_service(raxmon, TENANT_NAME, USERNAME, PASSWORD, KEYSTONE_ADMIN_ADDRESS, KEYSTONE_ADMIN_PORT)
print tenantid

