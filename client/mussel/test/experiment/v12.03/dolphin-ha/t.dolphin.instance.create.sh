#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables
description=${description:-}
display_name=${display_name:-}
is_cacheable=${is_cacheable:-}
is_public=${is_public:-}

## step

#
function test_instance_create() {
  create_instance 
}

## shunit2
. ${shunit2_file}

