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
  function shlog() { echo $*; }
  function curl() { echo curl $*; }
}

function test_call_api_curl_opts() {
  local preflight_uri=http://www.google.co.jp/

  assertEquals "$(call_api ${preflight_uri})" "curl -fsSkL -H ${http_header} ${preflight_uri}"
}

## shunit2

. ${shunit2_file}
