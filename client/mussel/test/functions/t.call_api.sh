#!/bin/bash

. ../../functions


test_call_api_success() {
  call_api http://www.google.co.jp/ >/dev/null 2>&1
  assertEquals $? 0
}

test_call_api_fail() {
  call_api http://www.example.co.jp/ >/dev/null 2>&1
  assertNotEquals $? 0
}

test_call_api_curl_opts() {
  function curl() { echo curl $*; }
  local preflight_uri=http://www.google.co.jp/

  assertEquals "$(call_api ${preflight_uri})" "curl -fSkL ${preflight_uri}"
}

. ../shunit2
