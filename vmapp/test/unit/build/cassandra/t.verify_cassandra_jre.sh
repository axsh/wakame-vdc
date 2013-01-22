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
  function egrep()  { echo egrep $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_verify_cassandra_jre() {
  verify_cassandra_jre ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
