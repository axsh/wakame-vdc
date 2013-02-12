#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})

## functions

function setUp() {
  # required
  image_id=${image_id:-wmi-centos1d}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-256}
  vifs=${vifs:-'{}'}
  ssh_key_id=${ssh_key_id:-ssh-demo}
}

function inst_hash() {
  local uuid=$1 key=$2 val=$3
  [[ "$(run_cmd ${namespace} show ${uuid} | egrep -w ^:${key}: | awk '{print $2}')" == "${val}" ]]
}

function retry_until() {
  local wait_sec=$1; shift;
  local blk="$@"

  local tries=0
  local start_at=$(date +%s)

  while :; do
    eval "${blk}" && {
      break
    } || {
      sleep 3
    }

    tries=$((${tries} + 1))
    if [[ $(($(date +%s) - ${start_at})) -gt ${wait_sec} ]]; then
      echo "Retry Failure: Exceed ${wait_sec} sec: Retried ${tries} times" >&2
      return 1
    fi
  echo ... ${tries} $(date +%Y/%m/%d-%H:%M:%S)
  done
}

###

function test_crud() {
  local uuid state

  uuid=$(run_cmd ${namespace} create | awk '$1 == ":id:" {print $2}')
  assertEquals $? 0

  retry_until 60 "inst_hash ${uuid} state running"

  run_cmd ${namespace} destroy ${uuid}
  assertEquals $? 0

  retry_until 60 "inst_hash ${uuid} state terminated"
}

## shunit2

. ${shunit2_file}
