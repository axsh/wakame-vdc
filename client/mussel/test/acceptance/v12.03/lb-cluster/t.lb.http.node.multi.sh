#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## wrapper

target_instance_num=${target_instance_num:-3} ${BASH_SOURCE[0]%/*}/t.lb.http.node.single.sh
