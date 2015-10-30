#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

if [[ -f /etc/selinux/config ]]; then
  sed -i "s/^\(SELINUX=\).*/\1disabled/" /etc/selinux/config
  egrep ^SELINUX= /etc/selinux/config
fi
