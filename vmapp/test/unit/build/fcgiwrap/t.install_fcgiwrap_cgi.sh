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

function test_install_fcgiwrap_envcgi() {
  install_fcgiwrap_envcgi ${chroot_dir}
  assertEquals 0 $?
}

function test_install_fcgiwrap_sleepcgi() {
  install_fcgiwrap_sleepcgi ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
