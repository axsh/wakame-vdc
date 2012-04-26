#!/bin/bash

set -e

## Setup OS files

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
