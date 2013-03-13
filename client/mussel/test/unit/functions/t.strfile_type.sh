#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare pair_file=${BASH_SOURCE[0]%/*}/pair.$$.txt

## functions

function setUp() {
  date > ${pair_file}
}

function tearDown() {
  rm -f ${pair_file}
}

function test_strfile_type_no_opts() {
  strfile_type 2>/dev/null
  assertNotEquals $? 0
}

function test_strfile_type_opts_str() {
  local foo=asdf
  assertEquals    "$(strfile_type foo)" "foo=${foo}"
  assertNotEquals "$(strfile_type foo)" "foo=${foo}aaa"
}

function test_strfile_type_opts_file() {
  local foo=${pair_file}
  assertEquals    "$(strfile_type foo)" "foo@${foo}"
  assertNotEquals "$(strfile_type foo)" "foo@${foo}aaa"
}

## shunit2

. ${shunit2_file}
