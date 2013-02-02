#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function setUp() {
  :
}

function test_urlencode_data_no_opts() {
  urlencode_data >/dev/null
  assertEquals $? 0
}

function test_urlencode_data_opts() {
  assertEquals "$(urlencode_data key=val)" "--data-urlencode key=val"
  assertEquals "$(urlencode_data key=val foo=bar)" "--data-urlencode key=val --data-urlencode foo=bar"
}

## shunit2

. ${shunit2_file}
