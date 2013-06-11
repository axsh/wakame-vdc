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
  mkdir ${chroot_dir}

  function chroot() { echo chroot $*; }
  function install_epel()  { echo install_epel  $*; }
  function install_nginx() { echo install_nginx $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_presetup_fcgiwrap() {
  presetup_fcgiwrap ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
