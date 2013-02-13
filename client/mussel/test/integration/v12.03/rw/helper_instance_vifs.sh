#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

### vifs

vifs_path=${BASH_SOURCE[0]%/*}/vifs.$$
vifs=${vifs_path}

### secg

security_group_uuid=

### ssh_key_pair

ssh_key_pair_path=${BASH_SOURCE[0]%/*}/key_pair.$$
ssh_key_pair_uuid=
public_key=${ssh_key_pair_path}.pub

## functions

### vifs

function render_vif_table() {
  cat <<-EOS
	{}
	EOS
}

### secg

function needless_secg() {
  false
}

function needs_secg() {
  needless_secg
}

function create_security_group() {
  local create_output="$(run_cmd security_group create)"
  echo "${create_output}"

  security_group_uuid=$(echo "${create_output}" | hash_value id)
}

function destroy_security_group() {
  run_cmd security_group destroy ${security_group_uuid}
}

### ssh_key_pair

function create_ssh_key_pair() {
  ssh-keygen -N "" -f ${ssh_key_pair_path} -C shunit2.$$ >/dev/null

  local create_output="$(run_cmd ssh_key_pair create)"
  echo "${create_output}"

  ssh_key_pair_uuid=$(echo "${create_output}" | hash_value id)
  # overwrite "ssh_key_id" defined in helper_instance.sh
  ssh_key_id=${ssh_key_pair_uuid}
}

function destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_pair_uuid}
  rm -f ${ssh_key_pair_path}*
}

### instance.create

function  before_create_instance() {
  create_ssh_key_pair
  needs_secg && { create_security_group; } || :
  render_vif_table > ${vifs_path}
}

function after_create_instance() {
  rm -f ${vifs_path}
}

### instance.destroy

function after_destroy_instance() {
  needs_secg && { destroy_security_group; } || :
  destroy_ssh_key_pair
}
