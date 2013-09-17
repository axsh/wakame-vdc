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

  function configure_lb_amqptools() { echo configure_lb_amqptools  $*; }
  function configure_lb_networking() { echo configure_lb_networking $*; }
  function prevent_lb_daemons_starting() { echo prevent_lb_daemons_starting $*; }
  function configure_lb_kmod() { echo configure_lb_kmod $*; }
  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_lb() {
  configure_lb ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
