#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

#ssh_user=${ssh_user:-root}
ip_handle_id=
network_id=

## functions

### step

function test_global_network_create(){
  network=192.168.2.0
  gw=192.168.2.1
  prefix=24
  domain_name=global
  network_mode=securitygroup
  ip_assignment=asc

  network_id=$(run_cmd network create | hash_value network_id)
  [[ -n ${network_id} ]]

  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
