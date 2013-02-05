#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function setUp() {
  mkdir -p ${suite_path}
  touch    ${suite_path}/execscript.sh
  touch    ${suite_path}/image.ini
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_preflight_builder_check() {
  preflight_builder_check
  assertEquals $? 0
}

function test_preflight_builder_check_execscript_not_found() {
  rm ${suite_path}/execscript.sh

  preflight_builder_check
  assertNotEquals $? 0
}

function test_preflight_builder_check_imageini_not_found() {
  rm ${suite_path}/image.ini

  preflight_builder_check
  assertNotEquals $? 0
}

## shunit2

. ${shunit2_file}
