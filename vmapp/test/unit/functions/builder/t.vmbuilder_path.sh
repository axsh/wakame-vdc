#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function setUp() {
  function git() { echo git $*; }
}

function test_vmbuilder_path() {
  vmbuilder_path
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
