#!/bin/bash

set -e

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
[ -z ${VDC_ROOT} ] && {
  pwd_path=$(cd $(dirname $0) && pwd)
} || {
  pwd_path=${VDC_ROOT}/tests/vdc.sh.d/rhel/
}
${pwd_path}/sysctl.sh < ${pwd_path}/sysctl.conf.d/bridge-if.conf

# stop system services.
for i in apparmor dnsmasq tgt; do
  [[ -x /etc/init.d/$i ]] && {
    /etc/init.d/$i stop
    chkconfig --del $i
  } || :
done

exit 0
