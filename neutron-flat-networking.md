## Introduction ##

This guide walks the user through creating a **flat** network within Quantum/Neutron in Openstack (Grizzly). Throughout the guide, Quantum and Neutron may be used interchangeably.

## Before You Start ##

This walkthrough assumes that the networking infrastructure is in place and that the nodes are reachable from an outside host. Configuration examples of the gear below will be provided.

The lab I am using is composed of the following gear:

* One controller node (Dell R710)
* One compute node (Dell R710)
* Gateway device (Cisco ASA 5510)
* Switch (Cisco 2960S)
* Openstack (Grizzly) has been installed on Controller and Compute nodes.

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







