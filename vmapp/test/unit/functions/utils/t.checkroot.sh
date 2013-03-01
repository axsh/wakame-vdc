#!/bin/bash
#
# requires:
#  bash
#  pwd
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## functions

function test_checkroot() {
  [[ $UID == 0 ]] && {
    checkroot 2>/dev/null
    assertEquals "$?" "0"
  } || {
    checkroot 2>/dev/null
    assertNotEquals "$?" "0"
  }
}

## shunit2

. ${shunit2_file}
