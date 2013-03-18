#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_uuid

### required

image_id=${image_id:-wmi-centos1d}
hypervisor=${hypervisor:-openvz}
cpu_cores=${cpu_cores:-1}
memory_size=${memory_size:-256}
ssh_key_id=

### vifs

vifs=${vifs:-'{}'}
vifs_path=${vif_path:-${BASH_SOURCE[0]%/*}/vifs.$$}

### secg

security_group_uuid=${security_group_uuid:-}
rule=${rule:-}
rule_path=${rule_path:-${BASH_SOURCE[0]%/*}/rule.$$}

### ssh_key_pair

ssh_key_pair_path=${ssh_key_pair_path:-${BASH_SOURCE[0]%/*}/key_pair.$$}
ssh_key_pair_uuid=${ssh_key_pair_uuid:-}
public_key=${public_key:-${ssh_key_pair_path}.pub}

## functions

### instance

function _create_instance() {
  setup_vif
  create_ssh_key_pair

  local create_output="$(run_cmd instance create)"
  echo "${create_output}"

  instance_uuid=$(echo "${create_output}" | hash_value id)
  retry_until "document_pair? instance ${instance_uuid} state running"

  cache_instance_param ${instance_uuid}
}

function _destroy_instance() {
  run_cmd instance destroy ${instance_uuid}
  retry_until "document_pair? instance ${instance_uuid} state terminated"

  destroy_ssh_key_pair
  teardown_vif

  clean_cached_instance_param ${instance_uuid}
}

### instance.cache

function generate_cache_file_path() {
  local uuid=$1
  echo  /tmp/_tmp.mussel.${uuid}.$$.txt
}

function cache_instance_param() {
  local instance_uuid=$1
  local cache_file_path=$(generate_cache_file_path ${instance_uuid})
  run_cmd instance show ${instance_uuid} > ${cache_file_path}
}

function cached_instance_param() {
  local instance_uuid=$1
  local cache_file_path=$(generate_cache_file_path ${instance_uuid})
  [[ -f "${cache_file_path}" ]] || return 0
  cat ${cache_file_path}
}

function clean_cached_instance_param() {
  local instance_uuid=$1
  local cache_file_path=$(generate_cache_file_path ${instance_uuid})
  [[ -f "${cache_file_path}" ]] || return 0
  rm -f ${cache_file_path}
}

### ssh_key_pair

function create_ssh_key_pair() {
  [[ -z "${ssh_key_pair_uuid}" ]] || {
    ssh_key_id=${ssh_key_pair_uuid}
    return 0
  }

  setup_ssh_key_pair ${ssh_key_pair_path}

  local create_output="$(description=${ssh_key_pair_path} run_cmd ssh_key_pair create)"
  echo "${create_output}"

  ssh_key_pair_uuid=$(echo "${create_output}" | hash_value id)
  ssh_key_id=${ssh_key_pair_uuid}
}

function destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_pair_uuid}
  teardown_ssh_key_pair ${ssh_key_pair_path}
}

### vifs

function needless_vif() {
  false
}

function needs_vif() {
  needless_vif
}

function render_vif_table() {
  cat <<-EOS
	{}
	EOS
}

function setup_vif() {
  needs_vif || return 0

  needs_secg && { create_security_group; } || :
  render_vif_table > ${vifs_path}
  vifs=${vifs_path}
}

function teardown_vif() {
  needs_vif || return 0

  rm -f ${vifs_path}
  needs_secg && { destroy_security_group; } || :
  rm -f ${rule_path}
}

### secg

function needless_secg() {
  false
}

function needs_secg() {
  needless_secg
}

function render_secg_rule() {
  :
}

function create_security_group() {
  render_secg_rule > ${rule_path}
  rule=${rule_path}
  local create_output="$(run_cmd security_group create)"
  echo "${create_output}"

  security_group_uuid=$(echo "${create_output}" | hash_value id)
}

function destroy_security_group() {
  run_cmd security_group destroy ${security_group_uuid}
}

#### instance hooks

function  before_create_instance() { :; }
function   after_create_instance() { :; }
function before_destroy_instance() { :; }
function  after_destroy_instance() { :; }

function create_instance() {
  before_create_instance
        _create_instance
   after_create_instance
}
function destroy_instance() {
  before_destroy_instance
        _destroy_instance
   after_destroy_instance
}
