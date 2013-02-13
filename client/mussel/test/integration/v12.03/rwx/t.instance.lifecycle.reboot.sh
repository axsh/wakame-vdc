#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function test_reboot_instance() {
  # :state: running
  # :status: online
  run_cmd instance reboot ${instance_uuid} >/dev/null
  assertEquals $? 0

  # :state: running
  # :status: online
  retry_until "check_document_pair instance ${instance_uuid} status online"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
