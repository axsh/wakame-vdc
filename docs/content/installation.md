## What are we installing?

This guide will set up a basic Wakame-vdc environment on a single host. When we are done with this guide we will have the following features available:

  * We will have a simple *machine image* running Ubuntu 10.04 (Lucid Lynx). We will be able to start instances of this image.

  * We will be able to create dynamic firewalls using [Security Groups](security-groups/index.md).

  * We will be able to [back up running instances](instance-backup/index.md) and turn them into new machine images.

  * We will be able to use either password or rsa key authentication when logging into instances.

## Installation requirements

  * A machine running [Centos](http://www.centos.org) 6.6 with x86 64 bit processor architecture. This can be either bare metal or a virtual machine. Instances are going to run as
[OpenVZ](http://openvz.org/Main_Page) containers so you don't need to worry about nested virtualization.

  * About 350 MB of disk space available in the `/opt` directory. Wakame-vdc itself is going to be placed there.

  * 1 GB of RAM should be more than enough for Wakame-vdc to run in this simple demo environment.

  * Some free disk space in the `/var/lib` directory. How much you need depends on how many instances you want to start. Wakame-vdc is going to place both its machine images and instances data in
`/var/lib/wakame-vdc`.

  This guide will install only a single machine image. The image itself is compressed and will take up 146 MB. Instances of it will take up 351 MB each when started.

  * Internet access. (to download rpm packages and machine images)

## What will this guide do to my machine?

  * Since we are going to use [OpenVZ](http://openvz.org/Main_Page), we will install OpenVZ's [modified Linux kernel](http://en.wikipedia.org/wiki/OpenVZ#Kernel).

  * We are going to set up a [Linux Bridge](http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge) and connect the host's network interface to it.

## Let's get started

### Yum repository setup

Add the official Wakame-vdc yum repository to `/etc/yum.repos.d`.

    sudo curl -o /etc/yum.repos.d/wakame-vdc.repo -R https://raw.githubusercontent.com/axsh/wakame-vdc/master/rpmbuild/wakame-vdc.repo

Add the Axsh OpenVZ yum repository to `/etc/yum.repos.d`. We are hosting an older version of OpenVZ on which Wakame-vdc is confirmed to be working.

    sudo curl -o /etc/yum.repos.d/openvz.repo -R https://raw.githubusercontent.com/axsh/wakame-vdc/master/rpmbuild/openvz.repo

Install [EPEL](https://fedoraproject.org/wiki/EPEL). We need to pull some OpenVZ dependencies from here.

    sudo yum install -y epel-release

### Install Dcmgr

The dcmgr package contains two things.

* The Wakame-vdc web API. This is Wakame-vdc's user interface. You tell Wakame-vdc to do stuff by making http requests to this API.

* The Wakame-vdc collector. This is Wakame-vdc's decision making organ. When you start an instance it decides which HVA (We'll tell you what an HVA is below) will host it, which IP address it
will get, etc.

Install the dcmgr package with the following command.

    sudo yum install -y wakame-vdc-dcmgr-vmapp-config

### Install HVA

The HVA (HyperVisor Agent) is the part of Wakame-vdc that actually starts instances. On a production environment, you would likely have several dedicated bare metal hosts for this. Right now we are
just going to install one HVA on the same machine as dcmgr.

**Remark:** In this installation the instances are going to be [OpenVZ](http://openvz.org/Main_Page) containers. Therefore we install the OpenVZ specific HVA package.

    sudo yum install -y wakame-vdc-hva-openvz-vmapp-config

### Install webui

This is Wakame-vdc's GUI. It's actually a [Rails application](http://rubyonrails.org) that sits in front of the dcmgr web API.

    sudo yum install -y wakame-vdc-webui-vmapp-config

### Reboot to load OpenVZ kernel

These Wakame-vdc packages have installed OpenVZ as a dependency. OpenVZ runs on a custom kernel. Reboot your machine so that kernel gets loaded.

### Set up bridged networking

Wakame-vdc uses bridged networking to allow users to connect to instances. We are going to set up a [Linux Bridge](http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge) to
attach instances to.

If you want to connect to instances from somewhere else than the host, we will need a network interface on the host that attaches an outside network to the bridge.

For the sake of this guide, we are going to assume that we will start instances in network `192.168.3.0/24`. The host has a network interface `eth0` with static IP address `192.168.3.100`.
**Change these values to match your environment.**

The network setup that this guide assumes places the host in the same network as the instances. That means the instances will have access to everything the host has access to. If the host can connect to the internet, the instances will be able to as well.

**Remark:** With this setup, the host itself will not be able to connect to the instances through networking because of security groups' arp wall. More info on that will be available in the near future, when we write a guide for security groups.

Create the file `/etc/sysconfig/network-scripts/ifcfg-br0` with the following contents

    DEVICE=br0
    TYPE=Bridge
    BOOTPROTO=static
    ONBOOT=yes
    NM_CONTROLLED=no
    IPADDR=192.168.3.100
    NETMASK=255.255.255.0
    GATEWAY=192.168.3.1
    DNS1=8.8.8.8
    DELAY=0

Next we need to attach `eth0` to the bridge. Modify the file `/etc/sysconfig/network-scripts/ifcfg-eth0` with the following contents.

**Remark:** If your machine's network interface is called `eth1`, `wlan0` or something else, make sure to edit its file instead. (e.g. ifcfg-eth1, ifcfg-wlan0, etc.) Also make sure to modify the *DEVICE=* line accordingly

    DEVICE="eth0"
    ONBOOT="yes"
    BRIDGE=br0
    NM_CONTROLLED=no

Restart the network.

**Be careful!** If you have made any mistakes setting up these files for your environment, this next command will cause networking to go down on your machine. Triple check these values if
you're running this guide on a remote machine!

    sudo service network restart

### Configuration

Next we are going to configure Wakame-vdc and download a machine image containing Ubuntu 10.04 that we can start instances of. You can either do it manually or run a script we have provided. Both methods will amount to the same result. The script should be easier but doing it manually will teach you more about Wakame-vdc.

#### Using the script

The script can be found here: [install_guide_demo_data.sh](https://raw.githubusercontent.com/axsh/wakame-vdc/master/scripts/install_guide_demo_data.sh)

It will perform all the steps explained below except reserving IP addresses. (which is optional)

You need to tell it about the network you want to start your instances in. Run the script without parameters to see how to use it.

After running the script and [optionally reserving ip addresses](#reserve-ip), skip over to the [Start Wakame-vdc](#start-wakame-vdc) section.

#### Manual configuration

The different Wakame-vdc services require their own config files. Unfortunately they currently aren't automatically installed with the rpm packages. Until we have that fixed, you will have to copy them over manually.

    sudo cp /opt/axsh/wakame-vdc/dcmgr/config/dcmgr.conf.example /etc/wakame-vdc/dcmgr.conf

    sudo cp /opt/axsh/wakame-vdc/dcmgr/config/hva.conf.example /etc/wakame-vdc/hva.conf

    sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/database.yml.example /etc/wakame-vdc/dcmgr_gui/database.yml

    sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/dcmgr_gui.yml.example /etc/wakame-vdc/dcmgr_gui/dcmgr_gui.yml

    sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/instance_spec.yml.example /etc/wakame-vdc/dcmgr_gui/instance_spec.yml

    sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/load_balancer_spec.yml.example /etc/wakame-vdc/dcmgr_gui/load_balancer_spec.yml

#### Create the Wakame-vdc database

Wakame-vdc uses a [MySQL](http://www.mysql.com) database. Start MySQL and create the database.

    sudo service mysqld start
    mysqladmin -uroot create wakame_dcmgr

We can use [Rake](https://github.com/ruby/rake) to create the database tables. Wakame-vdc comes with its own ruby binary that includes Rake.

    cd /opt/axsh/wakame-vdc/dcmgr
    /opt/axsh/wakame-vdc/ruby/bin/rake db:up

#### Register the HVA

As describe above, the HVA or host node is the part of Wakame-vdc that actually starts instances. Wakame-vdc can manage any number of these. The words HVA and host node will be use interchangeably in this guide.

Wakame-vdc recognises host nodes by their `node id`. That is a unique id that [AMQP](http://www.amqp.org) uses to identify each service. We will assign the id `demo1` to our HVA.

Edit the file `/etc/default/vdc-hva` and uncomment the following line:

    NODE_ID=demo1

Now our HVA process will start up with `demo1` as its `node id`. Next we need to add a database entry to let Wakame-vdc know how much memory, CPU power and disk space it has available, etc.

We can use the `vdc-manage` cli to do this. Of course the parameters of this command will vary depending on the capacity of your HVA. Adjust them accordingly.

    /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage host add hva.demo1 \
       --uuid hn-demo1 \
       --display-name "demo HVA 1" \
       --cpu-cores 100 \
       --memory-size 10240 \
       --hypervisor openvz \
       --arch x86_64 \
       --disk-space 102400 \
       --force

Remarks:
  * The `node id` would be *hva.demo1*. We set *demo1* in the above step but when the process starts, it is automatically prefixed by *hva*.

  * *Memory-size* and *cpu-cores* do not represent the actual memory size and CPU cores of the host node. They represent the amount of either to be offered to instances.

  Setting *cpu-cores* to 100 means that you can start for example 100 instances with 1 CPU core each or in another example, 50 instances with 2 CPU cores each.

  * The *force* flag is set so we can register the host node even though Wakame-vdc can't currently see it through AMQP. Since we haven't started the Wakame-vdc services yet, it's only natural that it can't see it yet. It will once we start them.

#### Download and register a machine image

Of course we can't start any instances if we don't have a machine image to instantiate. For this guide we are just going to download a simple machine image containing Ubuntu 10.04 (Lucid Lynx).

Wakame-vdc's default directory for keeping images is `/var/lib/wakame-vdc/images`. Create it.

    sudo mkdir -p /var/lib/wakame-vdc/images

Now download the image in that directory.

    cd /var/lib/wakame-vdc/images
    sudo curl -O http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-kvm-md-32.raw.gz

The image should have the following md5 sum. We will need it when registering it in the database.

    1f841b195e0fdfd4342709f77325ce29  ubuntu-lucid-kvm-md-32.raw.gz

Now we need to let Wakame-vdc know that it has a machine image to start instances from. First of all here's a brief explanation of how Wakame-vdc treats machine images. There are two terms we'll need to understand here. **Backup objects** and **machine images**. A *backup object* is basically a hard drive image. A *machine image* is a backup object that's bootable. In case of a linux instance, the *machine image* would hold the root partition.

To register both the *backup object* and the related *machine image*, we will again use the `vdc-manage` cli but since we are going to run more than one operation now, it's more efficient to call it without arguments. This will result in a special shell where we can run `vdc-manage` commands. This is more efficient because we only need to establish a connection to the database once and can then feed many commands through it.

    /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage

First of all we need to tell Wakame-vdc how we are storing these *backup objects*. We are currently just keeping them on the local file system.

    backupstorage add \
      --uuid bkst-local \
      --display-name "local storage" \
      --base-uri "file:///var/lib/wakame-vdc/images/" \
      --storage-type local \
      --description "storage on the local filesystem"

Now register the backup object and assign it to the local storage that we just made.

This image is compressed with gzip to save space. In order to properly manage its disk space usage, Wakame-vdc needs to know both the compressed size and uncompressed size of the image. These translate to the *size* and *allocation-size* options respectively.

    backupobject add \
      --uuid bo-lucid5d \
      --display-name "Ubuntu 10.04 (Lucid Lynx) root partition" \
      --storage-id bkst-local \
      --object-key ubuntu-lucid-kvm-md-32.raw.gz \
      --size 149084 \
      --allocation-size 359940 \
      --container-format gz \
      --checksum 1f841b195e0fdfd4342709f77325ce29

Next we tell Wakame-vdc that this backup object is a machine image that we can start instances of.

    image add local bo-lucid5d \
      --account-id a-shpoolxx \
      --uuid wmi-lucid5d \
      --root-device uuid:148bc5df-3fc5-4e93-8a16-7328907cb1c0 \
      --display-name "Ubuntu 10.04 (Lucid Lynx)"

#### Register a network

Wakame-vdc needs to know which network instances will be connected to. You can register more than one network and then decide which one to use when you start instances.

**Remark:** As described above, this guide assumes that network to be `192.168.3.0/24`. Make sure to change these values if you intend to use another network.

    network add \
      --uuid nw-demo1 \
      --ipv4-network 192.168.3.0 \
      --prefix 24 \
      --ipv4-gw 192.168.3.1 \
      --dns 8.8.8.8 \
      --account-id a-shpoolxx \
      --display-name "demo network"

Wakame-vdc is now aware of this network but it still doesn't know which IP addresses in it are available to assign to instances. Register a dhcp range.

    network dhcp addrange nw-demo1 192.168.3.1 192.168.3.254

<a name="reserve-ip"></a>
You might be worried because the gateway is included in dhcp range. Don't be. Wakame-vdc is smart enough to know that it can't use that IP address.

If you have other IP addresses inside the dhcp range that can not be used by Wakame-vdc, you need to reserve them so Wakame-vdc knows these can't be used. For example in this guide we were using 192.168.3.100 as the host node's ip address and therefore it can not be used. You can reserve it with the following command. If you do not have any IP addresses that need to be reserved, just skip this step.

    network reserve nw-demo1 --ipv4 192.168.3.100

Wakame-vdc needs to know which mac addresses are available to assign to instances.

    macrange add 525400 1 ffffff --uuid mr-demomacs

Next, Wakame-vdc needs to know which bridge to attach its intances' virtual network interfaces (vnics) to, and which interface on that bridge is connected to the outside world. You do that by registering a `dc network`.

    network dc add public --uuid dcn-public --description "the network instances are started in"
    network dc add-network-mode public securitygroup
    network forward nw-demo1 public

We're done with vdc-manage. Exit its shell.

    exit

Earlier in this guide we have set up a bridge named `br0` and it's connected to the outside world through a network interface `eth0`. If you are also using these names, you should be fine.

*If* you are using other names, you need to go update `/etc/wakame-vdc/hva.conf`. Find the following in that file and change it to match the names that you're using.

    dc_network('public') {
      bridge_type 'linux'
      interface 'eth0'
      bridge 'br0'
    }

#### Configure the GUI

The GUI is a rails application that requires its own database. Create it and initialize its tables using Rake.

    mysqladmin -uroot create wakame_dcmgr_gui
    cd /opt/axsh/wakame-vdc/frontend/dcmgr_gui/
    /opt/axsh/wakame-vdc/ruby/bin/rake db:init

The GUI uses user/password authentication. Wakame-vdc's web API has no authentication so on a production environment, you'd want to show only the GUI to the outside world while keeping the web API on a private network.

We're going to be talking about **users** and **accounts** here. Their meanings are slightly different.

* An account is where rights are assigned. An account will be allowed to start a certain amount of instances and own certain resources.

* A user is a username/password combination that has access to one or more accounts. You will log into the Wakame-vdc GUI as a user and get access to the resources owned by any accounts your user is associated with.

Users and accounts share a many-to-many relation. A user can belong to many accounts and an account can belong to many users.

The GUI database has a cli called `gui-manage` which is similar to vdc-manage.

    /opt/axsh/wakame-vdc/frontend/dcmgr_gui/bin/gui-manage

Let's use it to create an account for ourselves. This account with uuid `a-shpoolxx` is a special account that Wakame-vdc uses for certain shared resources.

    account add --name default --uuid a-shpoolxx

Next we'll add a user. The *login-id* is the name we're going to use when logging into the GUI.

    user add --name "demo user" --uuid u-demo --password demo --login-id demo

Now associate the user and the account.

    user associate u-demo --account-ids a-shpoolxx

We're done with gui-manage. Exit the shell.

    exit

### Start Wakame-vdc

Start the rabbitmq server. Wakame-vdc's different processes use AMQP to communicate. Rabbitmq-server is the AMQP exchange managing all that traffic.

    sudo service rabbitmq-server start

If you've been following this guide, MySQL should still be running. If it isn't running, start it.

    sudo service mysqld start

After all this hard work we should be able to get Wakame-vdc up and running. Start the upstart jobs.

These 4 upstart jobs can be started in any order as long as *rabbitmq-server* and *mysqld* have been started first.

    sudo start vdc-dcmgr
    sudo start vdc-collector
    sudo start vdc-hva
    sudo start vdc-webui

If everything went right, Wakame-vdc is now up and running. Start a web browser and surf to your machine's IP address on port 9000. If you're using the same IP address as this guide, that would be `192.168.3.100:9000`. Log in with user `demo` and password `demo`.

The `lucid5d` image has password login through ssh enabled. After starting instances you are able to log in using username `ubuntu` and password `ubuntu`. You are of course also able to log in using username `ubuntu` and a key pair registered with Wakame-vdc.

Check out the [basic usage guide](usage/index.md) if you're not sure were to go from here.

