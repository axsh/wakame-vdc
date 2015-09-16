#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

cat <<EOF >> ${chroot_dir}/etc/sysctl.conf

net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

EOF
