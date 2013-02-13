# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

## include files

function ssh() {
  $(which ssh) -o 'StrictHostKeyChecking no' $@
}

function remove_ssh_known_host_entry() {
  ipaddr=$(get_instance_ipaddr)
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
}

function get_instance_ipaddr() {
  run_cmd instance show ${instance_uuid} | hash_value address
}

function wait_for_instance_network_is_ready() {
  ipaddr=$(get_instance_ipaddr)
  retry_until "check_network_connection ${ipaddr}"
}

function wait_for_instance_sshd_is_ready() {
  ipaddr=$(get_instance_ipaddr)
  retry_until "check_port ${ipaddr} tcp 22"
}
