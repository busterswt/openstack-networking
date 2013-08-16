## Introduction ##

This guide walks the user through creating a **flat** network within Quantum/Neutron in Openstack (Grizzly). Throughout the guide, Quantum and Neutron may be used interchangeably.

## Before You Start ##

This walkthrough assumes that the networking infrastructure is in place and that the nodes are reachable from an outside host. Configuration examples of the gear below will be provided.

The lab I am using is composed of the following gear:

* One controller node (Dell R710 w/ Ubuntu 12.04 LTS)
* One compute node (Dell R710 w/ Ubuntu 12.04 LTS)
* Gateway device (Cisco ASA 5510)
* Switch (Cisco 2960S)
* Openstack (Grizzly) has been installed on Controller and Compute nodes.

Configure all appropriate IPs on the hosts to get connectivity working as expected. 

## About the Network ##

It might help to take a step back here and describe the various types of networks you can create within Neutron.

First, there are two major categories of networks:

- Provider Networks
- Tenant Networks

**Provider Networks** are networks usually created by the OpenStack administrator to map directly to an existing physical network in a data center. Useful network types in this category are **flat** (untagged) and **vlan** (tagged). Provider networks can be configured to be shared amongst tenants.

**Tenant Networks** are networks created by users within tenants/projects. Useful network types in this category are **vlan** (tagged) and **gre** (unique id). 

For the purpose of this walkthrough, I'll be focusing on **flat** provider networks to provide connectivity to instances.

## Diagram ##

The diagram below reflects an environment with a single L2 vlan and an L3 network connecting the firewall (gateway) to the servers.

![](http://i.imgur.com/9SNsxOr.png)

## Configuration ##

### Firewall Configuration ###

The firewall configuration is pretty straightforward. Interface e0/1 must be configured with the gateway address:

```
interface Ethernet0/1
 speed 100
 duplex full
 nameif mgmt
 security-level 100
 ip address 10.240.0.1 255.255.255.0
```

### Server Configuration ###

Right now, your servers likely have their IP configured directly on eth0. In order to utilize Neutron, the hosts must have a network bridge configured. This can be accomplished one of two ways:

- Configure eth0 as the bridge
- Configure another interface as the bridge

The former allows for the use of a single interface on the nodes. The IP of the machine would move from eth0 to the bridge interface. For this example, we'll use a single interface.

#### Interface Configuration ####

A bridge must be created on the controller and compute node(s).

Below is what a default eth0 configuration might look like:

```
auto eth0
iface eth0 inet static
	address 10.240.0.10
	netmask 255.255.255.0
	gateway 10.240.0.1
	nameserver 8.8.8.8
```

In order to configure the bridge, eth0 must be modified and the bridge interface created:

```
auto eth0
iface eth0 inet manual
	up ip l s $IFACE up
	down ip l s $IFACE down
	
iface br-eth0 inet static
	address 10.240.0.10
	netmask 255.255.255.0
	gateway 10.240.0.1
	nameserver 8.8.8.8
```

*NOTE: Do not set br-eth0 to auto. Due to the order of which process at started at boot, this must be accomplished in rc.local.*

Edit the /etc/rc.local file of each machine and add the following line before the 'exit' statement:

```
ifup br-eth0
exit 0
```

This will ensure the interface is brought up at the appropriate time during boot.

#### Openvswitch Configuration ####

Now it's time to create the bridge in OVS. The following commands will create a bridge called 'br-eth0' and place eth0 inside:

```
ovs-vsctl add-br br-eth0
ovs-vsctl add-port br-eth0 eth0
```

#### Changed to Environment json ####

A few changes must be made to the environment file in order to utilize the bridge for Neutron networking.

```
knife environment edit rpcs
```

Look for the section 'quantum : ovs : provider_networks'

```
"quantum": {
      "ovs": {
        "provider_networks":
```

The bridge configuration should be modified to mirror that below, if it doesn't already exist:

```
{
   "label": "ph-eth0",
   "bridge": "br-eth0",
   "vlans": "4092:4092"
}
```

*The vlan(s) listed above are arbitrary and won't be used in this example *

#### Implement the network changes ####

Once the bridge has been configure on the controller and compute nodes, run 'chef-client' to distribute the Neutron configuration changes.



