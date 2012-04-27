#!/bin/bash

set -e

# hostname and /etc/hosts configuration
[ -f /etc/hostname ] && {
  hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
} || :
egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo "127.0.0.1 $(hostname)" >> /etc/hosts

exit 0
