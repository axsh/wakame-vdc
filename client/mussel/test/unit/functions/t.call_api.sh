#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_call_api_curl_opts() {
  function curl() { echo curl $*; }
  local preflight_uri=http://www.google.co.jp/

  assertEquals "$(call_api ${preflight_uri})" "curl -fsSkL -H ${preflight_uri}"
}

## shunit2

. ${shunit2_file}
