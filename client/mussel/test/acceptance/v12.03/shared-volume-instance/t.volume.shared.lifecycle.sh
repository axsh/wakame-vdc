#!/bin/bash
#
#
#

## include
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## shunit2 setup

function oneTimeSetUp() {
  create_instance
}

function oneTimeTearDown() {
  destroy_instance
}

## step

# API test for shared volume instance lifecycle.
#
# 1. boot shared volume instance.
# 2. poweroff the instance.
# 3. poweron the instance.
# 4. terminate the instance.
function test_poweroff_instance_shared_volume(){
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
  assertEquals 0 $?
}

function test_poweron_intance_shared_volume(){
  run_cmd instance poweron ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state running"
  assertEquals 0 $?
}

## shunit2
. ${shunit2_file}
 
