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
