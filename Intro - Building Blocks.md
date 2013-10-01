###Neutron Networking: The Building Blocks of an OpenStack Cloud###

In this multi-part walkthrough series, I intend to dive into the various components of the OpenStack Neutron project, and to also provide working examples of multiple networking configurations for clouds built with Rackspace Private Cloud powered by OpenStack on Ubuntu 12.04 LTS. When possible, I’ll provide configuration file examples for those following along on an install from source.

In this first installment, I’ll briefly highlight Neutron features and terminology that will be useful for later installments. Future installments will include VLAN-based provider/tenant networks, GRE-based tenant networks, Open vSwitch troubleshooting, and more.

_New to OpenStack? Rackspace offers a complete open-source package, [Rackspace Private Cloud Software](http://www.rackspace.com/cloud/private/), that you're welcome to use at no cost. Download and follow along._


####Getting Started / What is Neutron?####

Search the internet for “Quantum Networking” and you’re bound to be overwhelmed with articles on the building blocks of our universe rather than the building blocks of OpenStack. The recent name change from Quantum to Neutron makes should make things a little easier to find, but it’s clear that the community is in dire need of real-world networking examples.

Before we can dig into the configuration of Neutron, it’s important to understand what it is and how it interacts with the rest of the Openstack architecture. Neutron is the ***networking component*** of OpenStack, and is a standalone service alongside other services such as Nova (Compute), Glance (Image), Keystone (authentication), and Horizon (Dashboard). Like those services, the deployment of Neutron involves deploying of several processes on each host.

- Neutron relies on Keystone for authentication and authorization of all API requests.

- Nova interacts with Neutron through API calls. As part of creating an instance, nova-compute communicates with the Neutron API to plug each virtual NIC on the instance into a particular Neutron network through the use of Open vSwitch.

- Horizon has a basic integration with the Neutron API, and allows tenants to create networks and subnets. Users are able to provision NICs to instances that connect to tenant networks and/or provider networks in order to provide connectivity to/from instances.

Thanks to its pluggable infrastructure, third-party and community developers can create plugins to extend the use and capabilities of Neutron within a Cloud. There are plugins for LBaaS (load-balancing as a service), VPNaaS, Layer 2 (OVS), Layer 3, and more.

####Open vSwitch / How does it fit in?####

Open vSwitch is an open source virtual switch that is highly utilized by Neutron. It can operate both as a soft switch running within the hypervisor, and as the control stack for physical switching devices. 
For OpenStack, Open vSwitch is installed as a kernel module or process. Much like a physical switch, Open vSwitch is responsible for the proper tagging and forwarding of traffic based on OVS port configuration. Aside from building the initial bridge(s), Neutron handles most all other interaction with OVS via the Open vSwitch plugin. It is possible, though beyond the scope of this article, to manipulate OVS outside of Neutron for further networking requirements.


####Basic Connectivity / Provider and Tenant Networks####

One of the core requirements of a networking service for OpenStack is to provide connectivity to and from instances.

There are two categories of networks that can be created within Neutron:
 
- Provider Networks
- Tenant Networks

Either network type (provider/tenant) can be used to provide connectivity to/from instances. However, there will need to be at least one provider network in your environment. A provider network can be used directly by instances themselves, or as the front-end (WAN) network for a Neutron router.

**Provider networks** are networks created by the OpenStack administrator that map directly to an existing physical network in the data center. An example of this would be a network behind a set of firewalls or load balancers that is routable within your data center. Useful network types in this category are ***flat*** (untagged) and ***vlan*** (802.1q tagged). It is possible to allow provider networks to be shared amongst tenants as part of the network creation process.

***Tenant networks*** are networks created by users within tenants, or groups of users. By default, networks created with tenants are not shared amongst other tenants. Useful network types in this category are ***vlan*** (802.1q tagged) and ***gre*** (unique id). With the use of the L3 agent and Neutron routers, it is possible to route between GRE-based tenant networks. Without a Neutron router, these networks are effectively isolated from each other (and everything else, for that matter).

![Sample Neutron Physical Network](http://i.imgur.com/JfIkzIS.png "Sample Neutron Physical Network")

_The diagram above represents a simple Neutron networking configuration that utilizes a tagged provider network for connectivity to the Internet, as well as two isolated GRE-based tenant networks for private communication between instances._

####Summary####

There’s so much more to Neutron than what’s been covered here, but the foundation has been laid for building simple networks for instance connectivity. With some basic configuration of physical network devices, and a little API magic, one can build a functioning cloud based on [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/) powered by [OpenStack](http://www.openstack.org).


_Have questions or comments? Feel free to contact or follow me on Twitter - [@jimmdenton](https://twitter.com/jimmdenton)_
