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
  mkdir -p ${chroot_dir}/etc/sysconfig
  touch    ${chroot_dir}/etc/sysconfig/spawn-fcgi
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_fcgiwrap_spawn_fcgi() {
  configure_fcgiwrap_spawn_fcgi ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
