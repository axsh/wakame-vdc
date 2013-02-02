#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=image

## functions

function setUp() {
  :
}

### help

function test_image_help_stderr_to_devnull_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

function test_image_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|destroy|index|show|xcreate]"
}

### index

function test_image_index() {
  extract_args ${namespace} index
  assertEquals $? 0
}

### show

function test_image_show_no_uuid() {
  extract_args ${namespace} show
  run_cmd ${MUSSEL_ARGS} 2>/dev/null
  assertNotEquals $? 0
}

function test_image_show_uuid() {
  extract_args ${namespace} show asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### destroy

function test_image_destroy() {
  extract_args ${namespace} destroy asdf
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

### xcreate

function test_image_xcreate() {
  extract_args ${namespace} xcreate
  run_cmd ${MUSSEL_ARGS}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
