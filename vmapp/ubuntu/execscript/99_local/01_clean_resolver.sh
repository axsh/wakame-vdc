#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

cp /dev/null ${chroot_dir}/etc/resolvconf/resolv.conf.d/original

