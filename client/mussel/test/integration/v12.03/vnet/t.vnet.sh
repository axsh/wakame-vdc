#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_with_vif.sh

## variables

target_instance_num=2

## functions

function test_vnet() {
  echo "true"
}

## shunit2

. ${shunit2_file}
