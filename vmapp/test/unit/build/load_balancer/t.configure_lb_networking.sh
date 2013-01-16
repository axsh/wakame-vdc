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
  mkdir -p ${chroot_dir}/etc/network-scripts

  echo ONBOOT=yes >> ${chroot_dir}/etc/sysconfig/network

  function sed() { echo sed $*; }
  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_lb_networking() {
  configure_lb_networking ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
