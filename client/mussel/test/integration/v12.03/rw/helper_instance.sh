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
ssh_key_id=${ssh_key_id:-ssh-demo}

## functions

### helper

function create_instance() {
  local create_output="$(run_cmd instance create)"
  echo "${create_output}"

  instance_uuid=$(echo "${create_output}" | hash_value id)
  retry_until "check_document_pair instance ${instance_uuid} state running"
}

function destroy_instance() {
  run_cmd instance destroy ${instance_uuid}
  retry_until "check_document_pair instance ${instance_uuid} state terminated"
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
