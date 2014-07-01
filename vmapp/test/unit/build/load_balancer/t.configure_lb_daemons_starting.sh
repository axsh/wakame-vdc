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
  mkdir -p ${chroot_dir}/etc/haproxy

  touch ${chroot_dir}/etc/haproxy/haproxy.cfg

  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_lb_daemons_starting() {
  configure_lb_daemons_starting ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
