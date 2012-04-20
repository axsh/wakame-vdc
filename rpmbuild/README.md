Installation and Preliminary Operations
=======================================

Installation Requirements
-------------------------

### System Requiremenets

+ RHEL 6.x

### Network Requirements

+ Local Area Network (LAN)
+ Internet connection


Installing RPM Builder Software
-------------------------------

### Donwloading Wakame-VDC

    # git clone git://github.com/axsh/wakame-vdc.git

### Installing Base Packages to Build RPMs

vdc.sh installs base packages to build RPMs.

    # cd ./wakame-vdc/
    # ./test/vdc.sh install::rhel

Building Wakame-VDC RPMs
------------------------

### Building RPMs using Makefile

rules is GNU Makefile. this is based on debian/rule.

    # ./rpmbuild/rules binary

Installing Wakame-VDC RPMs
--------------------------

    # yum install /root/rpmbuild/RPMS/x86_64/wakame-vdc-*.rpm
