#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

chroot ${chroot_dir} /etc/init.d/ntp stop
