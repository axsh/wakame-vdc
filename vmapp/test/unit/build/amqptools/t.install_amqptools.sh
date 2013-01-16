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

  function presetup_amqptools() { echo presetup_amqptools $*; }
  function prepare_amqptools()  { echo prepare_amqptools $*; }
  function build_amqptools()    { echo build_amqptools   $*; }
  function deploy_amqptools()   { echo deploy_amqptools  $*; }
  function cleanup_amqptools()  { echo cleanup_amqptools $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_amqptools() {
  install_amqptools ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
