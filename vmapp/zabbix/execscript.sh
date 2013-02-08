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

declare zabbix_version=${zabbix_version:-""}

## main

### wakame-init

install_epel ${chroot_dir}

chroot ${chroot_dir} <<EOF
wget http://www.zabbix.jp/binaries/relatedpkgs/rhel6/x86_64/zabbix-jp-release-6-5.noarch.rpm
rpm -ivh zabbix-jp-release-6-5.noarch.rpm
rm -f zabbix-jp-release-6-5.noarch.rpm

yum repolist

[[ -n "${zabbix_version}" ]] && {
  zabbix_version="-${zabbix_version}"
}

yum install -y zabbix${zabbix_version} \
   zabbix-server${zabbix_version} zabbix-server-mysql${zabbix_version} \
   zabbix-web${zabbix_version} zabbix-web-mysql${zabbix_version}

EOF

exit
