# Jargon Dictionary

## A

### Account

Accounts are used to manage resources on Wakame-vdc. Every command sent to the WebAPI must include an account UUID. Based on this account, Wakame-vdc will decide which resources to make available.

## B

### Backup Storage

Backup storage is a means of storing [backup objects](#backup-object). Backup objects can be stored on a local file system, served through http or using [Indelible FS](http://www.igeekinc.com/indeliblefs/en/indeliblefs.html) (experimental).

### Backup Object

A backup object is basically a hard drive image. Backup objects that hold bootable partitions are called [machine images](#machine-image).

## C

### Collector

The collector is one of Wakame-vdc's processes. It's in charge of making [scheduling decisions](#scheduling) and database access.

## D
## E

### Endpoint

An endpoint is a single part of the [WebAPI](#webapi) that the user can call to control Wakame-vdc. For example `GET http://<webapi ip>:<webapi port>/api/instances` is an endpoint. `POST http://<webapi ip>:<webapi port>/api/images` is another endpoint and so on.

## F
## G

### GUI

See [WebUI](#webui).

## H

### Host/Host Node

See [HVA](#HVA).

### HVA

The HVA (HyperVisor Agent) is the part of Wakame-vdc that actually starts [instances](#instance). On a production environment, you would likely have several dedicated bare metal hosts for this.

Also known as host or host node.

## I

### Instance

A virtual machine managed by wakame-vdc.

## J
## K
## L
## M

### Machine Image

A [backup object](#backup-object) that holds a bootable partition. You are able to start [instances](#instance) of machine images.

### Meta-data

In Wakame-vdc's context, meta-data usually refers to information that is passed to [instances](#instance) when they start. It includes for example the instance's IP addresses, network host name and thrusted public keys. Meta-data is usually delivered as files on an extra (tiny) hard drive.

## N

### NATbox

The NATbox is an optional Wakame-vdc node that provides one to one [network address translation](http://en.wikipedia.org/wiki/Network_address_translation) for [instances](#instance).

### Node

Refers to a server that a Wakame-vdc process runs on. Can be physical or a VM but not an [instance](#instance).

## O
## P
## Q
## R
## S

### Scheduling

The decision making process when starting a new instance. Deciding things like the network to join, the MAC and IP address to be assigned, which [HVA](#HVA) to use, etc. are referred to as scheduling. Scheduling takes place in Wakame-vdc's [collector](#collector).

### Security Group

Wakame-vdc's dynamically updating firewall. You can put [vnics](#vnic-/-vif) into groups that determine which network traffic is blocked and which is accepted. These firewalls are updated dynamically as the layout of the virtual data center changes. Read the [security groups guide](security-groups/index.md) for more details.

## T
## U

### User

A user is a name and password combination that you use to log into Wakame-vdc's GUI. A user can be associated to one or more [accounts](#account) which will decide what resources this user has access to.

**Remark:** Users is a concept exclusive to the GUI. The Wakame-vdc backend is only aware of [accounts](#account).

### User data

User data is an arbitrary field that users can set when starting an [instance](#instance). The user data will be delivered along with [meta-data](#meta-data) and will thus be accessible from inside the instance. For example users can create custom images with scripts in them that react to user data.

## V

### Vnic / Vif

Stands for Virtual Network Interface Card or Virtual Interface. In either case, the term refers to an [instance's](#instance) simulated network card.

## W

### WebAPI

This is Wakame-vdc's user interface. You tell Wakame-vdc to do stuff by making http requests to this API.

### WebUI

Wakame-vdc's GUI. It's actually a Rails application that sits in front of the [WebAPI](#webapi).

## X
## Y
## Z

