#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare config_file=${abs_dirname}/config.$$

## functions

function setUp() {
  cat <<EOS > ${config_file}
[DEFAULT]
arch = i386
ip = 192.168.0.100
part = vmbuilder.partition
user = user
name = user
pass = default
tmpfs = - 
firstboot = boot.sh
firstlogin = login.sh 

[ubuntu]
mirror = http://mirroraddress:9999/ubuntu
suite = intrepid 
flavour = virtual
addpkg = openssh-server, apache2, apache2-mpm-prefork, apache2-utils, apache2.2-common, dbconfig-common, libapache2-mod-php5, mysql-client, php5-cli, php5-gd, php5-ldap, php5-mysql, wwwconfig-common, mysql-server, unattended-upgrades, acpid
ppa = nijaba 

[kvm]
libvirt = qemu:///system 
EOS
}

function tearDown() {
  rm -f ${config_file}
}

function test_eval_ini_vm() {
  eval_ini ${config_file} DEFAULT

  assertEquals "${arch}"       "i386"
  assertEquals "${ip}"         "192.168.0.100"
  assertEquals "${part}"       "vmbuilder.partition"
  assertEquals "${user}"       "user"
  assertEquals "${name}"       "user"
  assertEquals "${pass}"       "default"
  assertEquals "${tmpfs}"      "-"
  assertEquals "${firstboot}"  "boot.sh"
  assertEquals "${firstlogin}" "login.sh"
}

function test_eval_ini_ubuntu() {
  eval_ini ${config_file} ubuntu

  assertEquals "${mirror}"  "http://mirroraddress:9999/ubuntu"
  assertEquals "${suite}"   "intrepid"
  assertEquals "${flavour}" "virtual"
  assertEquals "${addpkg}"  "openssh-server, apache2, apache2-mpm-prefork, apache2-utils, apache2.2-common, dbconfig-common, libapache2-mod-php5, mysql-client, php5-cli, php5-gd, php5-ldap, php5-mysql, wwwconfig-common, mysql-server, unattended-upgrades, acpid"
  assertEquals "${ppa}"     "nijaba"
}

function test_eval_ini_kvm() {
  eval_ini ${config_file} kvm

  assertEquals "${libvirt}" qemu:///system
}

## shunit2

. ${shunit2_file}
