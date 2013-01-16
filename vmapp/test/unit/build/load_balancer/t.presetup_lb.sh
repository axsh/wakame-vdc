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
  function install_epel() { echo install_epel $*; }
  function install_haproxy_rpm() { echo install_haproxy_rpm $*; }
  function install_libev_rpm() { echo install_libev_rpm $*; }
  function install_stud() { echo install_stud $*; }
  function install_rabbitmq_c() { echo install_rabbitmq_c $*; }
  function install_amqptools() { echo install_amqptools $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_presetup_lb() {
  presetup_lb ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
