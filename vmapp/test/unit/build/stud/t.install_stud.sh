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

  function presetup_stud() { echo presetup_stud $*; }
  function prepare_stud()  { echo prepare_stud $*; }
  function build_stud()    { echo build_stud   $*; }
  function deploy_stud()   { echo deploy_stud  $*; }
  function cleanup_stud()  { echo cleanup_stud $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_install_stud() {
  install_stud ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
