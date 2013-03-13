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

function needs_vif() { true; }

###

function test_show_instance_vifs_null() {
  assertEquals \
   "$(run_cmd instance show ${instance_uuid} | hash_value vif)" \
   "[]"
}

## shunit2

. ${shunit2_file}
