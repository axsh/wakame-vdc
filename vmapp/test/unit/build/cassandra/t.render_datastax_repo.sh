#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function test_render_datastax_repo() {
  render_datastax_repo
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
