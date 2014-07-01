#!/bin/bash

set -e
VDC_ROOT=${VDC_ROOT:?"VDC_ROOT needs to be set"}

## Setup OS files

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

${VDC_ROOT}/rpmbuild/helpers/sysctl.sh < ${VDC_ROOT}/contrib/etc/sysctl.d/30-bridge-if.conf
${VDC_ROOT}/rpmbuild/helpers/sysctl.sh < ${VDC_ROOT}/contrib/etc/sysctl.d/30-openvz.conf
${VDC_ROOT}/rpmbuild/helpers/set-openvswitch-conf.sh
${VDC_ROOT}/rpmbuild/helpers/add-loopdev.sh

# disable SELinux. ignore error for disabled case.
setenforce 0 || :

# stop system services.
for i in dnsmasq tgtd; do
  [[ -x /etc/init.d/$i ]] && {
    /etc/init.d/$i stop || :
    chkconfig --del $i
  } || :
done

exit 0
