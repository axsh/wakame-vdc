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
  function presetup_cassandra() { echo presetup_cassandra $*; }
  function install_dsc_rpm() { echo install_dsc_rpm $*; }
  function configure_cassandra() { echo configure_cassandra $*; }
  function verify_cassandra() { echo verify_cassandra $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_cassandra() {
  install_cassandra ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
