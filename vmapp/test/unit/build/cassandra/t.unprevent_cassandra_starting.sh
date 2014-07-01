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

function test_unprevent_cassandra_starting() {
  unprevent_cassandra_starting ${chroot_dir} | egrep -q -w "^chroot ${chroot_dir} bash -e -c chkconfig cassandra on"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
