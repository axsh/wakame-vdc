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

## functions

function setUp() {
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
}

function tearDown() {
  rm -f ${ssh_keypair_path}*
}

###

function test_crud() {
  local uuid
  local public_key=${ssh_keypair_path}.pub

  uuid=$(run_cmd ${namespace} create | awk '$1 == ":id:" {print $2}')
  assertEquals $? 0

  run_cmd ${namespace} show ${uuid}
  assertEquals $? 0

  run_cmd ${namespace} update ${uuid}
  assertEquals $? 0

  run_cmd ${namespace} destroy ${uuid}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
