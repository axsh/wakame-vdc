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
curl -O http://repo.zabbix.jp/relatedpkgs/rhel6/x86_64/zabbix-jp-release-6-6.noarch.rpm
rpm -ivh zabbix-jp-release-6-6.noarch.rpm
rm -f zabbix-jp-release-6-6.noarch.rpm

yum repolist

[[ -n "${zabbix_version}" ]] && {
  zabbix_version="-${zabbix_version}"
}

yum install -y zabbix${zabbix_version} \
   zabbix-server${zabbix_version} zabbix-server-mysql${zabbix_version} \
   zabbix-web${zabbix_version} zabbix-web-mysql${zabbix_version}

yum install -y ntp mysql-server

chkconfig ntpd on
chkconfig zabbix-server on

cat <<EOF2 > /etc/php.d/zabbix.ini
[PHP]
post_max_size = 32M
upload_max_filesize = 16M
max_execution_time = 600
max_input_time = 600
[Date]
date.timezone = $(date '+%Z')
EOF2

cat <<EOF2 >> /etc/my.cnf
[mysqld]
bind-address = 127.0.0.1
default-character-set=utf8
skip-character-set-client-handshake
EOF2

EOF

exit
