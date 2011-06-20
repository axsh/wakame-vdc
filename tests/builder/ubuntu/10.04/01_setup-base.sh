#!/bin/sh
#
# Ubuntu 10.04 LTS
#

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

builder_path=${builder_path:?"builder_path needs to be set"}


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

cp ${builder_path}/conf/sysctl.conf /etc/sysctl.conf
sysctl -p /etc/sysctl.conf


exit 0
