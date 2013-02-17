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

declare instance_ipaddr=

description=${description:-}
display_name=${display_name:-}
is_cacheable=${is_cacheable:-}
is_public=${is_public:-}

## functions

function after_create_instance() {
  run_cmd instance poweroff ${instance_uuid} >/dev/null
  retry_until "document_pair? instance ${instance_uuid} state halted"
}

### step

function test_backup_instance() {
  run_cmd instance backup ${instance_uuid}
  assertEquals $? 0
}


## shunit2

. ${shunit2_file}
