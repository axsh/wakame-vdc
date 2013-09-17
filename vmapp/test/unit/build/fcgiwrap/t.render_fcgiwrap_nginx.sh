#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function test_render_fcgiwrap_nginx() {
  render_fcgiwrap_nginx
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
