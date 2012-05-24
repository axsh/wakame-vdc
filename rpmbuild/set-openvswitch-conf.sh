#!/bin/bash

set -x
set -e

egrep ^BRCOMPAT= /etc/sysconfig/openvswitch -q || {
  echo BRCOMPAT=yes >> /etc/sysconfig/openvswitch
} && {
  sed -i 's,^BRCOMPAT=.*,BRCOMPAT=yes,' /etc/sysconfig/openvswitch
}
