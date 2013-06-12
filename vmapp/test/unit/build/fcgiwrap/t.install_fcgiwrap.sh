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

  function presetup_fcgiwrap() { echo presetup_fcgiwrap $*; }
  function prepare_fcgiwrap()  { echo prepare_fcgiwrap $*; }
  function build_fcgiwrap()    { echo build_fcgiwrap   $*; }
  function deploy_fcgiwrap()   { echo deploy_fcgiwrap  $*; }
  function cleanup_fcgiwrap()  { echo cleanup_fcgiwrap $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_fcgiwrap() {
  install_fcgiwrap ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
