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
  mkdir -p ${chroot_dir}/etc/sysconfig/network-scripts

  echo ONBOOT=yes > ${chroot_dir}/etc/sysconfig/network-scripts/ifcfg-eth0
  echo ONBOOT=yes > ${chroot_dir}/etc/sysconfig/network-scripts/ifcfg-eth1

  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_prevent_interfaces_booting_no_opts() {
  local nics=

  prevent_interfaces_booting ${chroot_dir}
  assertEquals 0 $?
}

function test_prevent_interfaces_booting_single() {
  local nics=eth0

  prevent_interfaces_booting ${chroot_dir} ${nics}
  assertEquals 0 $?

  egrep -q -w "^ONBOOT=no" ${chroot_dir}/etc/sysconfig/network-scripts/ifcfg-eth0
  assertEquals 0 $?
}

function test_prevent_interfaces_booting_multi() {
  local nics="eth0 eth1"
  prevent_interfaces_booting ${chroot_dir} ${nics}
  assertEquals 0 $?
}

function test_prevent_interfaces_booting_wildcard() {
  prevent_interfaces_booting ${chroot_dir} eth*
  assertEquals 0 $?
}


## shunit2

. ${shunit2_file}
