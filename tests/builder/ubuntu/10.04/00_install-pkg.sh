#!/bin/sh
#
# Ubuntu 10.04 LTS
#

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

builder_path=${builder_path:?"builder_path needs to be set"}

# core packages
deb_pkgs="
 ebtables iptables ipset ethtool
 openssh-server openssh-client
 ruby ruby-dev libopenssl-ruby1.8
 rdoc1.8 irb1.8
 g++
 curl libcurl4-openssl-dev
 mysql-server mysql-client libmysqlclient16-dev
 rabbitmq-server
 qemu-kvm kvm-pxe lxc iptables ebtables ubuntu-vm-builder
 dnsmasq
 open-iscsi open-iscsi-utils
 nginx
 libxml2-dev  libxslt1-dev
"
# apache2 apache2-threaded-dev libapache2-mod-passenger

rubygems_debs="
 rubygems_1.3.7-3_all.deb
 rubygems1.8_1.3.7-3_all.deb
"

# host configuration
hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo 127.0.0.1 $(hostname) >> /etc/hosts

# debian packages
DEBIAN_FRONTEND=${DEBIAN_FRONTEND} apt-get update
DEBIAN_FRONTEND=${DEBIAN_FRONTEND} apt-get -y upgrade
DEBIAN_FRONTEND=${DEBIAN_FRONTEND} apt-get -y install ${deb_pkgs}

cd /tmp
for rubygems_deb in ${rubygems_debs}; do
  [ -f ${rubygems_deb} ] || {
    wget http://us.archive.ubuntu.com/ubuntu/pool/universe/libg/libgems-ruby/${rubygems_deb}
  }
done
dpkg -i ${rubygems_debs}

exit 0
