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
  mkdir -p ${chroot_dir}/etc/nginx/conf.d
  touch    ${chroot_dir}/etc/nginx/conf.d/default.conf

  function sed() { echo sed $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

function test_configure_fcgiwrap_nginx() {
  configure_fcgiwrap_nginx ${chroot_dir}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
