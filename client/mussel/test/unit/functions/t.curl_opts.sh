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

### opts

function test_curl_opts() {
  assertEquals "$(curl_opts)" "-fsSkL -H ${http_header}"
}

## shunit2

. ${shunit2_file}
