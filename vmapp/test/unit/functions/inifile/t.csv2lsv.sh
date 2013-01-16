#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_csv2lsv_args() {
  assertEquals "$(csv2lsv "a, b, c")" "a
b
c"
}

function test_csv2lsv_filter() {
  assertEquals "$(echo "a, b, c" | csv2lsv)" "a
b
c"
}


## shunit2

. ${shunit2_file}
