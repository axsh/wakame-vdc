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
  function cd() { echo cd $*; }
}

function test_setup_vmbuilder() {
  setup_vmbuilder
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
