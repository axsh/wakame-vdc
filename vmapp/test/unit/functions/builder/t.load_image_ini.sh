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
  sample_image_ini > ${suite_path}/image.ini
}

function tearDown() {
  rm -rf ${suite_path}
}

function test_load_image_ini() {
  load_image_ini ${suite_path}/image.ini
  assertEquals 0 $?
}

function test_load_image_ini_inifile_not_found() {
  load_image_ini ${suite_path}/unknown.ini
  assertNotEquals 0 $?
}

## shunit2

. ${shunit2_file}
