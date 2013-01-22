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
  mkdir -p ${chroot_dir}

  function chroot() { echo chroot $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_unprevent_daemons_starting_single() {
  local svcs=sshd

  unprevent_daemons_starting ${chroot_dir} ${svcs} | egrep "chkconfig ${svcs} on$"
  assertEquals $? 0
}

function test_unprevent_daemons_starting_multi() {
  local svc_name="sshd network"
  assertEquals "$(unprevent_daemons_starting ${chroot_dir} ${svc_name} | wc -l)" 2
}


## shunit2

. ${shunit2_file}
