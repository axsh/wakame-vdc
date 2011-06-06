#!/bin/sh
#
# Ubuntu 10.04 LTS
#

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin


# core packages
deb_pkgs="
 openssh-server openssh-client
 ruby ruby-dev libopenssl-ruby1.8
 rdoc1.8 irb1.8
 g++
 curl libcurl4-openssl-dev
 mysql-server mysql-client libmysqlclient16-dev
 rabbitmq-server
 qemu-kvm kvm-pxe iptables ebtables ubuntu-vm-builder
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

# debian packages
apt-get update
apt-get -y upgrade
apt-get -y install ${deb_pkgs}

cd /tmp
for rubygems_deb in ${rubygems_debs}; do
  [ -f ${rubygems_deb} ] || {
    wget http://us.archive.ubuntu.com/ubuntu/pool/universe/libg/libgems-ruby/${rubygems_deb}
  }
done
dpkg -i ${rubygems_debs}


# disable apparmor
[ -x /etc/init.d/apparmor ] && {
  /etc/init.d/apparmor stop
  /usr/sbin/update-rc.d -f apparmor remove
}

# disable dnsmasq
[ -x /etc/init.d/dnsmasq ] && {
  /etc/init.d/dnsmasq stop
  /usr/sbin/update-rc.d -f dnsmasq remove
}

# kernel parameters
echo "# Configure kernel parameters ..."
[ -f /etc/sysctl.conf ] && {
  cp -p /etc/sysctl.conf /etc/sysctl.conf.`date +%Y%m%d-%H%M%S`
}

cat <<EOS > /etc/sysctl.conf
# common nat
net.ipv4.ip_forward=1
net.ipv4.conf.default.rp_filter=0
net.ipv4.ip_dynaddr=0
net.ipv4.tcp_syncookies=0
net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_ignore_bogus_error_responses=0

# any nics
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1

# conntrack
net.netfilter.nf_conntrack_acct=1
EOS

sysctl -p /etc/sysctl.conf


exit 0
