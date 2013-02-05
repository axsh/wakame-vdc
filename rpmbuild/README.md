Preliminary Operations and Installation
=======================================

Installation Requirements
-------------------------

### System Requiremenets

+ RHEL 6.x

### Network Requirements

+ Local Area Network (LAN)
+ Internet connection

### yum pre-setup

Download wakame-vdc.repo file and put it to your /etc/yum.repos.d/ repository.

    # curl -o /etc/yum.repos.d/wakame-vdc.repo -R https://raw.github.com/axsh/wakame-vdc/master/rpmbuild/wakame-vdc.repo

If you need OpenVZ container, add another repository.

    # curl -o /etc/yum.repos.d/openvz.repo     -R https://raw.github.com/axsh/wakame-vdc/master/rpmbuild/openvz.repo

Install epel-release.

    # yum install -y http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release

### Dcmgr installation

Install Dcmgr. The Dcmgr manages all assets in data centers.

    # yum install -y wakame-vdc-dcmgr-vmapp-config

### HVA installation

HVA stands for Hyper Visor Agent. It is internally used by the Dcmgr in order to manipulate the virtual machines.

    # yum install -y wakame-vdc-hva-full-vmapp-config


Configuring upstart system job
-------------------------------

Uncomment the following line in /etc/default/vdc-*.

    #RUN=yes

+ dcmgr node
  + /etc/default/vdc-collector
  + /etc/default/vdc-dcmgr
  + /etc/default/vdc-proxy
  + /etc/default/vdc-webui
  + /etc/default/vdc-auth
  + /etc/default/vdc-metadata
  + /etc/default/vdc-nsa
  + /etc/default/vdc-sta

+ hva node
  + /etc/default/vdc-hva

Or simply execute the following command.

    # sed -i -e 's/^#\(RUN=yes\)/\1/' /etc/default/vdc-*

Pre-setup Dcmgr
----------------

Copy all the necessary files.

### dcmgr(endpoints)

    # cp -f /opt/axsh/wakame-vdc/dcmgr/config/dcmgr.conf.example /etc/wakame-vdc/dcmgr.conf

### webui

    # cp -f /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/database.yml.example           /etc/wakame-vdc/dcmgr_gui/database.yml
    # cp -f /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/dcmgr_gui.yml.example          /etc/wakame-vdc/dcmgr_gui/dcmgr_gui.yml
    # cp -f /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/instance_spec.yml.example      /etc/wakame-vdc/dcmgr_gui/instance_spec.yml
    # cp -f /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/load_balancer_spec.yml.example /etc/wakame-vdc/dcmgr_gui/load_balancer_spec.yml


Set the appropriate VDC_ROOT environment variable.

### pre-setup proxy

    # echo "$(eval "VDC_ROOT=/var/lib/wakame-vdc; echo \"$(curl -s https://raw.github.com/axsh/wakame-vdc/master/tests/vdc.sh.d/proxy.conf.tmpl)\"")" > /etc/wakame-vdc/proxy.conf

Pre-setup Hva
--------------

    # cp -f /opt/axsh/wakame-vdc/dcmgr/config/hva.conf.example /etc/wakame-vdc/hva.conf


Configuring Database
--------------------

Check if the database is specified in /etc/wakame-vdc/dcmgr.conf


### dcmgr(endpoints)

    database_uri 'mysql2://localhost/wakame_dcmgr?user=root'


Check if the following section is described in /etc/wakame-vdc/dcmgr_gui/database.yml

### webui

    development:
       adapter: mysql2
       database: wakame_dcmgr_gui
       host: localhost
       user: root
       password:



-----------------------

### dcmgr(endpoints)

Check if the amqp server is specified in /etc/wakame-vdc/dcmgr.conf

    amqp_server_uri 'amqp://localhost/'

### agents (collector, hva, etc.)

In the following 4 files,

+ /etc/default/vdc-collector
+ /etc/default/vdc-hva
+ /etc/default/vdc-nsa
+ /etc/default/vdc-sta

check if the following lines are described.

    #AMQP_ADDR=127.0.0.1
    #AMQP_PORT=5672



Creating Database
-----------------


Before creating the database, you need to launch mysql-server.

    # service mysqld start

To automatically launch mysql-server, execute the following command.

    # chkconfig mysqld on

If you need additional demonstration data, please type the following commands.
NOTICE: this script will erase all related database at first. We recommend to backup before doing this.

    # yum install -y wakame-vdc-vdcsh
    # /opt/axsh/wakame-vdc/tests/vdc.sh init

Stop here, you're done!

Developer Zone
==============

If you are a developer, please do the following.

Installing RPM Builder Software
-------------------------------

### Donwloading Wakame-VDC

    # git clone git://github.com/axsh/wakame-vdc.git

### Installing Base Packages to Build RPMs

vdc.sh installs base packages to build RPMs.

    # cd ./wakame-vdc/
    # ./tests/vdc.sh install::rhel

Building Wakame-VDC RPMs
------------------------

### Building RPMs using Makefile

rules is GNU Makefile. this is based on debian/rule.

    # ./rpmbuild/rules binary

Installing Wakame-VDC RPMs
--------------------------

    # yum install /root/rpmbuild/RPMS/x86_64/wakame-vdc-*.rpm

Developing Wakame-VDC RPMs
--------------------------

### Deploying Wakame-VDC

    $ [ -d ~/rpmbuild/BUILD/ ] || mkdir -p ~/rpmbuild/BUILD/
    $ cd ~/rpmbuild/BUILD/
    $ git clone git://github.com/axsh/wakame-vdc.git wakame-vdc-12.03
    $ cd wakame-vdc-12.03

### Modifying files.

    $ vi ./path/to/file...

#### Building RPMs using SPEC.

    $ rpmbuild -bc --short-circuit ./rpmbuild/SPECS/wakame-vdc.spec
    $ rpmbuild -bb --short-circuit ./rpmbuild/SPECS/wakame-vdc.spec
