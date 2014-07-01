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
  mkdir ${chroot_dir}

  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_presetup_rabbitmq_c() {
  presetup_rabbitmq_c ${chroot_dir} | egrep "^chroot ${chroot_dir}"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
