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
  mkdir -p ${chroot_dir}/tmp/fcgiwrap-master
  touch    ${chroot_dir}/tmp/fcgiwrap-master/Makefile

  function chroot() { echo chroot $*; }
  function curl() { echo curl $*; }
  function tar()  { echo tar  $*; }
  function sed()  { echo sed  $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_prepare_fcgiwrap() {
  prepare_fcgiwrap ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
