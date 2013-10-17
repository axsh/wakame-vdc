#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## wrapper

target_instance_num=${target_instance_num:-3}
# set SHUNIT_PARENT to sourced file to make sure to run test_xx functions in sourced file.
SHUNIT_PARENT=${BASH_SOURCE[0]%/*}/t.lb.tcp.node.single.sh
. ${SHUNIT_PARENT}
