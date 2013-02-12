# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

## include files

. ${BASH_SOURCE[0]%/*}/../helper_shunit2.sh

## group variables

declare ssh_keypair_path=${BASH_SOURCE[0]%/*}/keypair.$$
declare rule_path=${BASH_SOURCE[0]%/*}/rule.$$
declare vifs_path=${BASH_SOURCE[0]%/*}/vifs.$$

## configuarable variables

image_id=${image_id:-wmi-centos1d}
hypervisor=${hypervisor:-openvz}
cpu_cores=${cpu_cores:-1}
memory_size=${memory_size:-256}
network_id=${network_id:-nw-demo1}

## test local variables

inst_id=
ipaddr=
secg_id=
ssh_key_id=

## group functions

function ssh() {
  $(which ssh) -o 'StrictHostKeyChecking no' $@
}

##

function render_secg_rule() {
  :
}

function render_vif_table() {
  :
}

function generate_ssh_key_pair() {
  ssh-keygen -N "" -f ${ssh_keypair_path} -C shunit2.$$ >/dev/null
}

function remove_ssh_known_host_entry() {
  ipaddr=$(get_instance_ipaddr)
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
}

function create_ssh_key_pair() {
  public_key=${ssh_keypair_path}.pub
  ssh_key_id=$(run_cmd ssh_key_pair create | hash_value id)
}

function create_security_group() {
  render_secg_rule > ${rule_path}
  rule=${rule_path}
  secg_id=$(run_cmd security_group create | hash_value id)
}

function create_instance() {
  render_vif_table > ${vifs_path}
  vifs=${vifs_path}
  inst_id=$(run_cmd instance create | hash_value id)
}

function get_instance_ipaddr() {
  run_cmd instance show ${inst_id} | hash_value address
}

function wait_for_instance_state_is() {
  local state=$1
  retry_until "check_document_pair instance ${inst_id} state ${state}"
}

function wait_for_instance_network_is_ready() {
  ipaddr=$(get_instance_ipaddr)
  retry_until "check_network_connection ${ipaddr}" >/dev/null
}

function wait_for_instance_sshd_is_ready() {
  ipaddr=$(get_instance_ipaddr)
  retry_until "check_port ${ipaddr} tcp 22" >/dev/null
}


function destroy_instance() {
  run_cmd instance destroy ${inst_id}
}

function destroy_ssh_key_pair() {
  run_cmd ssh_key_pair destroy ${ssh_key_id}
}

function destroy_security_group() {
  run_cmd security_group destroy ${secg_id}
}
