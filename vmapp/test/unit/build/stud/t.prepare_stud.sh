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
  mkdir -p ${chroot_dir}/tmp/stud-master
  touch    ${chroot_dir}/tmp/stud-master/Makefile

  function wget() { echo wget $*; }
  function tar()  { echo tar  $*; }
  function sed()  { echo sed  $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_prepare_stud() {
  prepare_stud ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
