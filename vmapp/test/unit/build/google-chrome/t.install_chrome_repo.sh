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
  mkdir -p ${chroot_dir}/etc/yum.repos.d
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_chrome_repo() {
  install_chrome_repo ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
