#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_alarm.sh

## variables
tags=$(cat ${BASH_SOURCE[0]%/*}/tag.list)

## functions
function test_create_alarm() {
  for tag in ${tags}; do
    local params="tag=${tag} match_pattern=error"
    for i in {0..2}; do
      alarm_uuid=$(run_cmd alarm create | hash_value uuid)
      assertEquals $? 0

      display_name=${alarm_uuid} run_cmd alarm update ${alarm_uuid}
      assertEquals $? 0
    done
  done
}

## shunit2

. ${shunit2_file}
