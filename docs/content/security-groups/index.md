## Overview

In Wakame-vdc, every virtual network interface (vnic) will have its own firewall. These firewalls are implemented using [Netfilter](http://www.netfilter.org). Even if one instance has multiple vnics, they will still each have their own firewall.

These firewalls are implemented on the [HVA](../jargon-dictionary.md#hva) and network traffic is filtered before it reaches the instance's vnic.

![screenshot](img/security-groups/low_level_overview.png)

From the user's perspective, this firewall is controlled through *security groups*. A user can create security groups and place vnics in them. Depending on what groups a vnic is in, its firewall will decide what network traffic is allowed to pass through.

Security groups are dynamic. Instances can enter and leave groups on the fly and groups can change their rules of allowed network traffic at any time. No restarts of any kind are required. Whenever a change happens in the security groups layout, the firewall of every vnic affected will update itself automatically.

![screenshot](img/security-groups/high_level_overview.png)

## Features

Security groups come with three distinct features.

* Isolation
* Rules
* Reference

**Remark:** Technically we don't put instances in security groups. We put their virtual network interfaces (vnics) in security groups. An instance with multiple vnics is able to have different security groups for each vnic.

### Isolation

By default all instances are isolated from each other. That means that all L2 traffic including ARP and IPv4 between them is blocked.

Why do we block ARP? Because Wakame-vdc supports multi-tenancy. Imagine two users managing their own instances on the same Wakame-vdc installation. In reality those instances are probably started in the same network. We don't want user A's instances to be able to see user B's instances and vice versa. That would be an obvious security issue. That is why all ARP is blocked in addition to IPv4.

By putting two vnics in the same Security Group, they will get **full ARP and IPv4 access** to each other.

The following image shows a couple of instances with vnics in different security groups and isolation between them works.

![screenshot](img/security-groups/isolation.png)

### Rules

By default all incoming traffic to instances is blocked. Security Group rules allow you to open specific TCP ports, UDP ports, or ICMP traffic.

The following image shows an example of a security group that opens TCP port 22 with 3 vnics in it.

![screenshot](img/security-groups/rules.png)

#### Syntax

For TCP and UDP protocols:

    <protocol>:<start-port>,<end-port>,ip4:<ip-address>

For the ICMP protocol:

    icmp:<icmp-type>,<icmp-code>,ip4:<ip-address>

A list of the ICMP types and codes can be found [here](http://www.faqs.org/docs/iptables/icmptypes.html). The wildcard to accept any type or code is -1.

**Examples**

A rule that opens TCP port 22 for all incoming traffic.

    tcp:22,22,ip4:0.0.0.0

A rule that opens TCP ports 1024 to 2048 to all ip addresses from local network 192.168.0.0/24.

    tcp:1024,2048,ip4:192.168.0.0/24

A rule that opens UDP port 53 to google's dns server located at 8.8.8.8.

    udp:53,53,ip4:8.8.8.8

A rule that allows all incoming ICMP traffic (like ping).

    icmp:-1,-1,ip4:0.0.0.0

A rule that accepts *network unreachable* ICMP messages (type/code: 3/0) from ip address 192.168.2.1.

    icmp:3,0,ip4:192.168.2.1

### Reference

A reference rule is a special type of rule. Instead of opening up a port to an ip range, you can open up a port to another security group. Take the following example.

Imagine you have a database server instance and a bunch of other instances that run database clients. You could put them all in one security group together. The clients would get access to the server but they'd have full access rather than just the port that the database server is listening on. You could put the database server in one security group and add a rule for each client instance that opens just the database port. This time the instances don't have unneeded full access but you will have to go add a new rule manually every time a new client instance is started. Neither solutions are ideal.

This is where reference comes in. Reference allows you to put the database server in one security group and all clients together in another. You can add a *reference rule* to the server's group that will open only the listening database port **to all vnics in the clients' group**. When vnics are added to or removed from the clients' group, the firewall is updated automatically to take them into account.

![screenshot](img/security-groups/reference.png)

#### Syntax

The instances is the same as regular rules, except you write another security group's uuid insetad of an IP address.

**Example**

The database rule described above would look like this:

For this example two security groups exist. *sg-dbsrv* which has the database server in it and sg-dbclnts which has the clients in it. *sg-dbsrv* would contain the following rule that opens MySQL's listening port 3306 to all vnics in the client group.

    tcp:3306,3306,sg-dbclnts

## Creating security groups using the Wakame-vdc GUI

After logging into the GUI, click on `Security Groups` in the menu on the left. Next click on `Create Security Group`.

![screenshot](img/security-groups/06_security_groups_create.png)

The following dialog will pop up. In here you will be able to write rules for your security group.

![screenshot](img/security-groups/07_security_groups_dialog.png)

## Adding and removing vnics from security groups using the Wakame-vdc GUI

When starting an instance using the Wakame-vdc GUI, you will be required to put its vnic(s) in at least one security group. Although it is possible to start instances with vnic(s) that aren't in any security groups (which results in all incoming network traffic being blocked) by querying the WebAPI directly, the GUI requires one or more to be set.

When starting an instance, you'll see the following dialog. The instance's security groups can be set here. When using the GUI, all vnics of this instance will be placed in the same security groups. If you wish to have one instance with multiple vnics in different security groups, you will need to call the [WebAPI](../jargon-dictionary.md#webapi) directly.

![screenshot](img/security-groups/start_instance.png)

When you want to change the security groups of a running instance's vnic(s), click on Instances in the menu on the left of the main GUI window. Next to your instance you should see a button saying `edit`. Click it.

![screenshot](img/security-groups/instance_edit_button.png)

The dialog that pops up will allow you to set the security groups for *all* vnics of the instance.

![screenshot](img/security-groups/edit_instance.png)

