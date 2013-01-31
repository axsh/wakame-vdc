#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_cmd_help() {
  assertEquals \
   "`cmd_help command sub-commands 2>&1`" \
          "$0 command [help|sub-commands]"
}

## shunit2

. ${shunit2_file}
