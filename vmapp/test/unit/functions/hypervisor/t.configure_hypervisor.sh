#!/bin/bash
#
# requires:
#  bash
#  pwd
#  date, egrep
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare chroot_dir=${abs_dirname}/_chroot.$$

## public functions

function setUp() {
  mkdir -p ${chroot_dir}/etc
  function chroot() { echo chroot $*; }
  function flush_etc_sysctl() { echo flush_etc_sysctl $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_hypervisor() {
  VDC_HYPERVISOR=
  configure_hypervisor ${chroot_dir}
  assertEquals $? 0
}

function test_configure_hypervisor_lxc() {
  VDC_HYPERVISOR=lxc
  configure_hypervisor ${chroot_dir} | egrep -q -w "flush_etc_sysctl ${chroot_dir}"
  assertEquals $? 0
}

function test_configure_hypervisor_unknown() {
  VDC_HYPERVISOR=unknown
  configure_hypervisor ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
