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
  function verify_cassandra_jre() { echo verify_cassandra_jre $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_verify_cassandra() {
  verify_cassandra ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
