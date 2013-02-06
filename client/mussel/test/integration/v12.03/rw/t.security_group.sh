#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})

## functions

###

function test_crud() {
  local uuid rule

  rule=tcp:22,22,ip4:0.0.0.0/0
  uuid=$(run_cmd ${namespace} create | awk '$1 == ":id:" {print $2}')
  assertEquals $? 0

  run_cmd ${namespace} show ${uuid}
  assertEquals $? 0

  rule=icmp:-1,-1,ip4:0.0.0.0/0
  run_cmd ${namespace} update ${uuid}
  assertEquals $? 0

  rule=udp:53,53,ip4:0.0.0.0/0
  run_cmd ${namespace} update ${uuid}
  assertEquals $? 0

  run_cmd ${namespace} destroy ${uuid}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
