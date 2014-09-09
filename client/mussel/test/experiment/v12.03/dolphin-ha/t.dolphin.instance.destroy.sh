#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files
. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function setUp() {
  load_instance_file
}

## step

#
function test_instance_destroy() {
  destroy_instance
}

## shunit2
. ${shunit2_file}

