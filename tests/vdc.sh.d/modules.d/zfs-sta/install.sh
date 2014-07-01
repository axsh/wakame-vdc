#!/bin/bash

set -e

yum localinstall --nogpgcheck http://archive.zfsonlinux.org/epel/zfs-release-1-3.el6.noarch.rpm
yum install zfs

exit 0
