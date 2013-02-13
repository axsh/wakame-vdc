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

### instance.create

function  before_create_instance() {
  needs_secg && { create_security_group; } || :
  render_vif_table > ${vifs_path}
}

function after_create_instance() {
  rm -f ${vifs_path}
}

### instance.destroy

function after_destroy_instance() {
  needs_secg && { destroy_security_group; } || :
}
