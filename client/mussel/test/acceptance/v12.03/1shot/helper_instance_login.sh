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
  local ipaddr=$1
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
}

function wait_for_network_to_be_ready() {
  local ipaddr=$1
  retry_until "check_network_connection ${ipaddr}"
}

function wait_for_sshd_to_be_ready() {
  local ipaddr=$1
  retry_until "check_port ${ipaddr} tcp 22"
}
