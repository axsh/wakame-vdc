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
  mkdir -p ${chroot_dir}/tmp

  function rsync() { echo rsync $*; }
  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_presetup_jre6() {
  presetup_jre6 ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
