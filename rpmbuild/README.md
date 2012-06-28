Installation and Preliminary Operations
=======================================

Installation Requirements
-------------------------

### System Requiremenets

+ RHEL 6.x

### Network Requirements

+ Local Area Network (LAN)
+ Internet connection

### yum pre-estup

Downloading repo file and put it to your /etc/yum.repos.d/ repository.

    # curl -R https://raw.github.com/axsh/wakame-vdc/master/rpmbuild/wakame-vdc.repo -o /etc/yum.repos.d/wakame-vdc.repo

Base Installation
-----------------

    # yum install wakame-vdc

Dcmgr Installation
------------------

    # yum install http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-7.noarch.rpm
    # yum install wakame-vdc-dcmgr-vmapp-config

Hva installation
----------------

    # yum search  wakame-vdc-hva
    # yum install wakame-vdc-hva-<hypervisor>-vmapp-config

Developer Zone
==============

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
