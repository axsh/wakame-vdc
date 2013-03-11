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
  mkdir -p ${chroot_dir}/etc

  cat <<EOS > ${chroot_dir}/etc/rc.local
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
EOS

 function rsync() { echo rsync $*; }
 function chmod() { echo chmod $*; }
 function chown() { echo chown $*; }
}

function tearDown() {
  rm -rf ${chroot_dir}
}

##

function test_install_wakame_init_unknown() {
  install_wakame_init ${chroot_dir} unknown
  assertNotEquals $? 0
}

##

function test_install_wakame_init_md() {
  install_wakame_init ${chroot_dir} md centos
  assertEquals $? 0
}

function test_install_wakame_init_ms() {
  install_wakame_init ${chroot_dir} ms centos
  assertEquals $? 0
}

function test_install_wakame_init_mcd() {
  install_wakame_init ${chroot_dir} mcd centos
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
