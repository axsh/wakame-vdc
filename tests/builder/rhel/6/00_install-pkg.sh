#!/bin/sh
#
# Ubuntu 10.04 LTS
#

export LANG=C
export LC_ALL=C

builder_path=${builder_path:?"builder_path needs to be set"}


# core packages
rpm_pkgs="
 ebtables iptables ethtool vconfig
 openssh-server openssh-clients
 ruby ruby-devel rubygems
 make gcc-c++ gcc
 curl openssl-devel
 mysql-server mysql mysql-devel
 dnsmasq
 iscsi-initiator-utils scsi-target-utils
 nginx
 libxml2-devel libxslt-devel
 initscripts erlang
 qemu-kvm
 dosfstools
 nc
"
# rpm-build libcap-devel docbook-utils

# host configuration
egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo 127.0.0.1 $(hostname) >> /etc/hosts

#  some packages use ubuntu-natty. ex. lxc
echo $(dirname $0)

rpm -qa | grep epel || rpm -ivh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-5.noarch.rpm
yum install -y ${rpm_pkgs}

rpm -qa | grep rabbitmq-server || rpm -ivh http://www.rabbitmq.com/releases/rabbitmq-server/v2.6.1/rabbitmq-server-2.6.1-1.noarch.rpm
which bundle >/dev/null || gem install bundler --no-ri --no-rdoc

# enable mysql
[ -x /etc/init.d/mysqld ] && {
  /etc/init.d/mysqld start
  /sbin/chkconfig mysqld on
}

exit 0
