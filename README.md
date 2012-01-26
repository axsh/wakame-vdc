Wakame-VDC
============

Wakame-VDC is a toolkit for IaaS cloud.

See details for http://wakame.jp/wiki/ (in English)

Features:

* Operation
 * Web GUI
 * RESTful API

* Hypervisor
 * KVM
 * LXC

* Network
 * Security Group (L3)
 * Distributed Firewall
 * Distributed NAT

* Storage
 * Solaris ZFS + iSCSI
 * Tired snapshot management

* Management
 * Per Account Quota


Required Components
--------------------

* RabbitMQ (>= 1.7.2)
* MySQL (>= 5.1.41)
* nginx (>= 0.7.65)
* Ruby (>= 1.8.7)
* RubyGems (>= 1.3.7)


Building a Development Environment
----------------------------------

Ubuntu 10.04

    $ sudo apt-get install git-core
    $ sudo gem install bundler
    $ sudo ln -s  /var/lib/gems/1.8/bin/bundle /usr/local/bin/
    $ git clone git://github.com/axsh/wakame-vdc.git
    $ cd ./wakame-vdc/
    $ sudo -s
    # ./tests/vdc.sh install
    # ./tests/vdc.sh run

RHEL6/CentOS6

    # yum install -y git
    # git clone git://github.com/axsh/wakame-vdc.git
    # cd ./wakame-vdc/
    # ./tests/vdc.sh install
    # ./tests/vdc.sh run


License
---------

Copyright (c) Axsh Co.
Components are included distribution under LGPL 3.0 and Apache 2.0
