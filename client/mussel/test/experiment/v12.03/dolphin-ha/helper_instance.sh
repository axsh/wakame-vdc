#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_ipaddr=

function needs_vif() { true; }
function needs_secg() { true; }

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}

## functions

### instance

function render_vif_table() {
  cat <<-EOS
	{"eth0":{"index":"0","network":"${vifs_eth0_network_id}","security_groups":"${security_group_uuid}"}}
	EOS
}

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
}

function after_create_instance() {
  cache_instance_file ${instance_uuid}
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  wait_for_network_to_be_ready ${instance_ipaddr}
  wait_for_sshd_to_be_ready    ${instance_ipaddr}
}

function before_destroy_instance() {
  ssh_key_pair_uuid="$(cached_instance_param ${instance_uuid}   | egrep ' ssh-' | awk '{print $2}')"
  security_group_uuid="$(cached_instance_param ${instance_uuid} | egrep ' sg-'  | awk '{print $2}')"
}

function after_destroy_instance() {
  clean_cached_instance_file
}

### instance.cache

function generate_cache_file_path() {
  local uuid=$1
  echo /tmp/_tmp.mussel.${uuid}.txt
}

### instance cache file path 

function instance_file_path() {
  echo ${BASH_SOURCE[0]%/*}/instance.txt
}

function cache_instance_file() {
  local instance_uuid=$1
  local instance_file_path=$(instance_file_path)

  echo "instance_uuid=${instance_uuid}"           >  ${instance_file_path}
  echo "vifs_path=${vifs_path}"                   >> ${instance_file_path}
  echo "rule_path=${rule_path}"                   >> ${instance_file_path}
  echo "ssh_key_pair_path=${ssh_key_pair_path}"   >> ${instance_file_path}
}

function load_instance_file() {
  local instance_file_path=$(instance_file_path)
  [[ -f "${instance_file_path}" ]] || return 0
  source ${instance_file_path}
}

function clean_cached_instance_file() {
  local instance_file_path=$(instance_file_path)
  [[ -f "${instance_file_path}" ]] || return 0
  rm -f ${instance_file_path}
}

### shunit2 setup

