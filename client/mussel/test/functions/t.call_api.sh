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

. ../shunit2
