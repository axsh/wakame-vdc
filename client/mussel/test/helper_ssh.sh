# -*-Shell-script-*-
#
# requires:
#   bash
#

function ssh() {
  $(which ssh) -o 'StrictHostKeyChecking no' $@
}

function remove_ssh_known_host_entry() {
  local ipaddr=$1
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
}

function generate_ssh_keypair() {
  local output_keyfile=$1; shift; eval local $@
  ssh-keygen -N "" -f ${output_keyfile} -C ${comment:-shunit2.$$}
}
