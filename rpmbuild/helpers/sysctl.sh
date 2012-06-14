#!/bin/bash
#
# $ sysctl.sh config file
# $ sysctl.sh < ./config
# $ command | sysctl.sh
#
set -e

function apply_sysctl() {
  cat | egrep -v '^#|^$' | while read line; do
    set ${line}

#    # current parameter
#    [ "$(sysctl $1)" = "$1 = $3" ] || {
#      sysctl -w "$1 = $3"
#    }

    # /etc/sysctl.conf
    egrep ^$1 /etc/sysctl.conf -q || {
      echo "$1 = $3" >> /etc/sysctl.conf
    } && {
      sed -i "s,^$1.*,$1 = $3," /etc/sysctl.conf
    }

    # verify
    egrep ^$1 /etc/sysctl.conf
  done

#  sysctl -p
}

if [ $# == 0 ]; then
  cat | apply_sysctl
else
  while [ $# -gt 0 ]; do
    [ -f $1 ] && apply_sysctl < $1
    shift
  done
fi
