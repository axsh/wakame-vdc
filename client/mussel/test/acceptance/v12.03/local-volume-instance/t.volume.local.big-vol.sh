#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## wrapper

blank_volume_size=${blank_volume_size:-10G}
. ${BASH_SOURCE[0]%/*}/t.volume.local.base.sh
