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
  touch            > ${suite_path}/execscript.sh

  function checkroot() { :; }
  function vmbuilder_path() { echo echo vmbuilder_path $*; }
  function tar() { echo tar $*; }
}

function tearDown() {
  rm -rf ${suite_path}
}

function test_build_vm() {
  build_vm ${suite_path}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
