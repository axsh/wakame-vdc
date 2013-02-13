#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare ssh_key_pair_path=${BASH_SOURCE[0]%/*}/key_pair.$$

declare ssh_key_pair_uuid
declare public_key=${ssh_key_pair_path}.pub

## functions

function oneTimeSetUp() {
  ssh-keygen -N "" -f ${ssh_key_pair_path} -C shunit2.$$ >/dev/null
}

function oneTimeTearDown() {
  rm -f ${ssh_key_pair_path}*
}

###

function test_create_ssh_key_pair() {
  ssh_key_pair_uuid=$(run_cmd ssh_key_pair create | hash_value id)
  assertEquals $? 0
}

function test_show_ssh_key_pair() {
  run_cmd ssh_key_pair show ${ssh_key_pair_uuid} >/dev/null
  assertEquals $? 0
}

function test_update_ssh_key_pair() {
  run_cmd ssh_key_pair update ${ssh_key_pair_uuid} >/dev/null
  assertEquals $? 0
}

function test_destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_pair_uuid} >/dev/null
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
