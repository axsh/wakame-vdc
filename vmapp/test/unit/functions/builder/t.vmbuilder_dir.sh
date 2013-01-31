#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function test_vmbuilder_dir() {
  vmbuilder_dir
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
