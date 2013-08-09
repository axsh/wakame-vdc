Wakame-VDC
==========

[![Code Climate](https://codeclimate.com/github/axsh/wakame-vdc.png)](https://codeclimate.com/github/axsh/wakame-vdc)

Wakame-VDC is the Data Center Level Hypervisor.

See details for http://wakame.jp/wiki/ (in English)

Features:

* Operation
 * Web GUI
 * RESTful API

* Hypervisor
 * KVM
 * VMware ESXi
 * LXC
 * OpenVZ

* Network
 * Security Group (L3)
 * Distributed Firewall
 * Distributed NAT
 * Open vSwitch (OpenFlow) + Trema Based Controller

* Storage
 * Solaris ZFS + iSCSI
 * Indelible FS
 * Tired snapshot management

* Management
 * Per Account Quota

Install
-------

* RPM (RHEL6/CentOS6)
 * https://github.com/axsh/wakame-vdc/tree/master/rpmbuild

Required Components
--------------------

* RabbitMQ (>= 2.7.1)
* MySQL (>= 5.1.66)
* nginx (>= 1.0.15)
* Ruby (>= 2.0.0)
* RubyGems (>= 1.8.23)


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
    # ./tests/vdc.sh install::rhel
    # ./tests/vdc.sh run

Users
-----

* Kyushu Electric Power Co., Ltd. ( http://www.kyuden.co.jp/en_index.html )
* National Institute of Informatics ( http://www.nii.ac.jp/en/ )
* NTT PC Communications ( http://www.nttpc.co.jp/english/ )
* Kyocera Communication Systems Co., Ltd. ( http://www.kccs.co.jp/english/ )

If you already use this software, please let me know. Thank you.

Contributors
------------

Special thanks to all contributors for submitting patches. A full list
of contributors including their patches can be found at:

https://github.com/axsh/wakame-vdc/contributors

License
---------

Copyright (c) Axsh Co.
Components are included distribution under LGPL 3.0 and Apache 2.0
