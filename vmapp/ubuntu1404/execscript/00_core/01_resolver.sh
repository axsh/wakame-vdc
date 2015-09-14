#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

cat <<EOF > ${chroot_dir}/etc/resolv.conf
nameserver 8.8.8.8
EOF

