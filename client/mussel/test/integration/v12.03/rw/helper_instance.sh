#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_uuid state

### required

image_id=${image_id:-wmi-centos1d}
hypervisor=${hypervisor:-openvz}
cpu_cores=${cpu_cores:-1}
memory_size=${memory_size:-256}
vifs=
ssh_key_id=

### ssh_key_pair

ssh_key_pair_path=${BASH_SOURCE[0]%/*}/key_pair.$$
ssh_key_pair_uuid=
public_key=${ssh_key_pair_path}.pub

## functions

### instance

function create_instance() {
  create_ssh_key_pair

  local create_output="$(run_cmd instance create)"
  echo "${create_output}"

  instance_uuid=$(echo "${create_output}" | hash_value id)
  retry_until "check_document_pair instance ${instance_uuid} state running"
}

function destroy_instance() {
  run_cmd instance destroy ${instance_uuid}
  retry_until "check_document_pair instance ${instance_uuid} state terminated"

  destroy_ssh_key_pair
}

### ssh_key_pair

function create_ssh_key_pair() {
  ssh-keygen -N "" -f ${ssh_key_pair_path} -C shunit2.$$ >/dev/null

  local create_output="$(run_cmd ssh_key_pair create)"
  echo "${create_output}"

  ssh_key_pair_uuid=$(echo "${create_output}" | hash_value id)
  ssh_key_id=${ssh_key_pair_uuid}
}

function destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_pair_uuid}
  rm -f ${ssh_key_pair_path}*
}

### shunit2 setup

#### instance hooks

function  before_create_instance() { :; }
function   after_create_instance() { :; }
function before_destroy_instance() { :; }
function  after_destroy_instance() { :; }

function oneTimeSetUp() {
  before_create_instance
         create_instance
   after_create_instance
}

function oneTimeTearDown() {
  before_destroy_instance
         destroy_instance
   after_destroy_instance
}
