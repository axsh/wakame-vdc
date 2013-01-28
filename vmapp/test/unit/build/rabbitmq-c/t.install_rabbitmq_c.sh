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

  function presetup_rabbitmq_c() { echo presetup_rabbitmq_c $*; }
  function prepare_rabbitmq_c()  { echo prepare_rabbitmq_c $*; }
  function build_rabbitmq_c()    { echo build_rabbitmq_c   $*; }
  function deploy_rabbitmq_c()   { echo deploy_rabbitmq_c  $*; }
  function cleanup_rabbitmq_c()  { echo cleanup_rabbitmq_c $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_rabbitmq_c() {
  install_rabbitmq_c ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
