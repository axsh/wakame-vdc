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
  mkdir -p ${chroot_dir}

  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_ntp_rpm() {
  install_ntp_rpm ${chroot_dir} | egrep -q -w "^chroot ${chroot_dir} bash -e -c yum install -y ntp"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
