#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
# Host node control functions to emulate accidental shutdown.
# TODO: add support for more hypervisors.
. ${BASH_SOURCE[0]%/*}/vmware-ws.sh

## variables

image_uuid='wmi-imgzfs1'
description=${description:-}
display_name=${display_name:-}
# allow to wait for longer time during instance boot.
retry_wait_sec_at_boot=360

## hook functions

declare last_result_path=""

function setUp() {
  last_result_path=$(mktemp --tmpdir=${SHUNIT_TMPDIR})
}

function new_instance() {
  local instance_uuid=$(image_id=${image_uuid} run_cmd instance create | hash_value id)
  assertEquals 0 $?

  # :state: running
  # :status: online
  RETRY_WAIT_SEC=${retry_wait_sec_at_boot} \
    retry_until "document_pair? instance ${instance_uuid} state running" or_fail_with \
    "document_pair? instance ${instance_uuid} state terminated"
  assertEquals 0 $?

  echo $instance_uuid
}

function off_instance() {
  local instance_uuid=$1

  run_cmd instance destroy ${instance_uuid}
  retry_until "document_pair? instance ${instance_uuid} state terminated"
}

### step

if type kill_host_node_real > /dev/null; then
  :
else
  _shunit_fatal "Failed to load host_node control functions"
fi

function kill_host_node() {
  local host_node_uuid="$1"

  kill_host_node_real "${host_node_uuid}"
}

function check_host_node() {
  local host_node_uuid="$1"

  check_host_node_real "${host_node_uuid}"
}

function test_ha_host_node() {
  local -a instance_uuids host_node_uuids
  local i

  for i in $(seq 2); do
    instance_uuids[$i]=$(new_instance)
    assertEquals 0 $?

    run_cmd instance show "${instance_uuids[$i]}" | ydump > $last_result_path
    host_node_uuids[$i]=$(yfind ':host_node:' < $last_result_path)
  done

  kill_host_node "${host_node_uuids[2]}"
  while :; do
    run_cmd instance show "${instance_uuids[2]}" | grep host_node >&2
    run_cmd instance show "${instance_uuids[2]}" | ydump > $last_result_path
    if [[ $(yfind ':host_node:' < $last_result_path) != "${host_node_uuids[2]}" ]]; then
      break;
    fi
    sleep 1
  done

  sleep 5

  for i in ${instance_uuids[@]}; do
    off_instance "$i"
  done
}

## shunit2

. ${shunit2_file}
