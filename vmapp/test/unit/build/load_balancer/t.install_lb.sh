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

  function presetup_lb() { echo presetup_lb $*; }
  function configure_lb() { echo configure_lb $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_lb() {
  install_lb ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
