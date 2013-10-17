#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## wrapper

blank_volume_size=${blank_volume_size:-10G}
# set SHUNIT_PARENT to sourced file to make sure to run test_xx functions in sourced file.
SHUNIT_PARENT=${BASH_SOURCE[0]%/*}/t.volume.local.base.sh
. ${SHUNIT_PARENT}
