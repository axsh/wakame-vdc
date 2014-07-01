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
  vdc_metadata_type=md

  vm_name=builder
  vm_distro_name=centos
  vm_hypervisor=kvm
  vm_distro_name=centos
  vm_distro_ver=6
  vm_arch=x86_64
  vm_keepcache=1
  vm_fstab_type=label
  vm_sshd_passauth=no
  vm_rootsize=768
  vm_swapsize=128
}

function test_vmbootstrap() {
  vmbootstrap ${chroot_dir}
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
