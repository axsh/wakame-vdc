#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})
declare ssh_keypair_path=${BASH_SOURCE[0]%/*}/keypair.$$

declare uuid
declare public_key=${ssh_keypair_path}.pub

## functions

function oneTimeSetUp() {
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
}

function oneTimeTearDown() {
  rm -f ${ssh_keypair_path}*
}

###

function test_create_ssh_key_pair() {
  uuid=$(run_cmd ${namespace} create | awk '$1 == ":id:" {print $2}')
  assertEquals $? 0
}

function test_show_ssh_key_pair() {
  run_cmd ${namespace} show ${uuid} >/dev/null
  assertEquals $? 0
}

function test_update_ssh_key_pair() {
  run_cmd ${namespace} update ${uuid} >/dev/null
  assertEquals $? 0
}

function test_destroy_ssh_key_pair() {
  run_cmd ${namespace} destroy ${uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
