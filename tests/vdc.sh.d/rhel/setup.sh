#!/bin/bash

set -e

## Setup OS files

# hostname and /etc/hosts configuration
hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo "127.0.0.1 $(hostname)" >> /etc/hosts

# always overwrite 10-hva-sysctl.conf since it may have updated entries.
#[ -d /etc/sysctl.d/ ] || mkdir /etc/sysctl.d/
#echo "Configuring sysctl.conf parameters ... /etc/sysctl.d/10-hva-sysctl.conf"
#cp ${VDC_ROOT}/debian/config/10-hva-sysctl.conf /etc/sysctl.d/
# reload sysctls
#initctl start procps
#(
#  CONSOLETYPE=dummy
#  . /etc/init.d/functions
#  RHEL6.0 does not support "apply_sysctl".
#  apply_sysctl
#)
sed -i "s/^net.bridge.bridge-nf-call-iptables.*/net.bridge.bridge-nf-call-iptables = 1/"  /etc/sysctl.conf

# stop system services.
for i in apparmor dnsmasq tgt; do
  [[ -x /etc/init.d/$i ]] && {
    /etc/init.d/$i stop
    chkconfig --del $i
  } || :
done

exit 0
