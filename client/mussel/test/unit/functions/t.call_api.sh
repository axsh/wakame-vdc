#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function setUp() {
  function shlog() { echo $*; }
  function curl_opts() { :; }
}

### opts

function test_call_api_curl_opts() {
  local preflight_uri=http://www.google.co.jp/

  assertEquals "$(call_api ${preflight_uri})" "curl ${preflight_uri}"
}

## shunit2

. ${shunit2_file}
