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
  mkdir -p ${chroot_dir}/etc/modprobe.d
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_lb_kmod() {
  configure_lb_kmod ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
