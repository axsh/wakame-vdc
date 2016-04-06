## Why virtualize?

Think about the concept of virtual machines like [VirtualBox](https://www.virtualbox.org) or [KVM](http://www.linux-kvm.org) for a bit. What do they do? They run on some kind of physical hardware. It can be either a big tower PC or a small laptop. The exact same virtual machines can run on either hardware.

A virtual machine is software and software can be copied. Therefore virtual machines can be easily backed up and reverted to a previous state. Much the same way, virtual machines can easily be cloned or migrated to different hardware.

A virtual data center like Wakame-vdc extends this from a single machine to an entire data center. Wakame-vdc consists of several components that communicate through the network. You can install all these components together on a single laptop, or you can run them all on separate servers in a physical data center. On top of either you are able to run a virtual data center.

## Virtual data center components

There are three things that make up a data center, either physical or virtual: **servers**, **network** and **storage**.

### Servers

Wakame-vdc virtualizes servers by implementing the very virtual machine software (hypervisors) mentioned at the top of this page. Check out the [F.A.Q.](faq.md) to see which ones it uses exactly.

Wakame-vdc keeps track of a number of *machine images*. These are essentially virtual servers. It doesn't boot these up directly though. Instead it boots *instances* of these images. That basically means that it starts up a copy of a machine image, leaving the original image unchanged. In theory you can start up an infinite amount of instances.

### Network

Wakame-vdc by itself has only partial network virtualization. Namely, it has a virtualized firewall that updates itself automatically as the data center changes. This is refered to as security groups.

In order to let users connect to instances, Wakame-vdc uses bridged networking. This is explained in the usage guides of several hypervisors and beyond the scope of this wiki.

In order to do full network virtualization, Wakame-vdc integrates with our other product, [OpenVNet](http://www.openvnet.com). OpenVNet achieves full network virtualization using [OpenFlow](http://archive.openflow.org). This is currently still experimental.

### Storage

Wakame-vdc virtualizes storage using [iSCSI](http://en.wikipedia.org/wiki/ISCSI) targets or [NFS](http://en.wikipedia.org/wiki/Network_File_System). In the case of iSCSI, several backends are supported.

From the user's perspective, Wakame-vdc's storage consists of virtual disks referred to as *volumes*. A volume can be compared to an external hard drive. It can be attached to and detached from instances on the fly.

## Why virtualize the data center?

Virtualizing the data center provides these merits:

* Portability

* Scalability

* Reliability

### Portability

At the top of this page we mentioned that Wakame-vdc can run on all kinds of hardware ranging from a single laptop to a big physical data center with many servers. Once you've created a virtual data center on that single laptop, you are able to migrate it over to a production environment running on a big physical data center with relative ease.

### Scalability

When you need to add a new server to a physical data center, what do you do? You buy the hardware, put it in place and set up the networking infrastructure and firewalls to connect it. It's a very time consuming and expensive process.

In a virtual data center like Wakame-vdc, all you do is click a few buttons. This creates a new server (instance) and puts it in the data center while network settings get configured automatically. Depending on the size of the instance's machine image, it comes up in a matter of seconds.

Now imagine that a user has a website running on top of a virtual data center. They get a traffic spike and the instances hosting their website just aren't enough any more. They are now able to quickly create a bunch of new instances to help you take care of that extra traffic. Once things settle down again, you can easily terminate those instances.

### Reliability

A virtual data center provides much more flexible failover alternatives. From the user's point of view it doesn't matter on which physical server an instance is running. All the user cares about is being able to connect to their instance. If a physical server fails, instances can be quickly migrated to another physical server.

Since a virtual data center is software and software can be copied, it is easy to take regular backups of certain servers or even the entire data center.

