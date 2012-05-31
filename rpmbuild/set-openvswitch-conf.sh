#!/bin/bash

set -x
set -e

[ -f /etc/sysconfig/openvswitch ] || {
  echo no such file: /etc/sysconfig/openvswitch >&2
  exit 0
}

egrep ^BRCOMPAT= /etc/sysconfig/openvswitch -q || {
  echo BRCOMPAT=yes >> /etc/sysconfig/openvswitch
} && {
  sed -i 's,^BRCOMPAT=.*,BRCOMPAT=yes,' /etc/sysconfig/openvswitch
}
