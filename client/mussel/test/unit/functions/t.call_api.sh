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
  function curl_opts() { :; }
}

### opts

function test_call_api_curl_opts() {
  local preflight_uri=http://www.google.co.jp/

  assertEquals "$(call_api ${preflight_uri})" "curl ${preflight_uri}"
}

### http_header

function test_call_api_curl_defined_http_header() {
  local preflight_uri=http://www.google.co.jp/
  local http_header=X_VDC_ACCOUNT_UUID:a-shpoolxx

  call_api >/dev/null
  assertEquals $? 0
}

function test_call_api_curl_empty_http_header() {
  local preflight_uri=http://www.google.co.jp/
  local http_header=

  call_api 2>/dev/null
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
