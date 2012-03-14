#!/bin/bash

set -e

## Setup OS files

# hostname and /etc/hosts configuration
hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo "127.0.0.1 $(hostname)" >> /etc/hosts

# always overwrite 10-hva-sysctl.conf since it may have updated entries.
echo "Configuring sysctl.conf parameters ... /etc/sysctl.d/10-hva-sysctl.conf"
cp ${VDC_ROOT}/debian/config/10-hva-sysctl.conf /etc/sysctl.d/
# reload sysctls
initctl start procps

# stop system services.
for i in apparmor dnsmasq tgt; do
  [[ -x /etc/init.d/$i ]] && {
    /etc/init.d/$i stop
    update-rc.d -f $i remove
  } || :
done

exit 0
