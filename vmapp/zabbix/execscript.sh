#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/epel.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main

### wakame-init

install_epel ${chroot_dir}

chroot ${chroot_dir} <<EOF
rpm -ivh http://www.zabbix.jp/binaries/relatedpkgs/rhel6/x86_64/zabbix-jp-release-6-5.noarch.rpm

yum repolist

EOF

exit
