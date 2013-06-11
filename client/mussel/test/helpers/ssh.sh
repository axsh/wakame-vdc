# -*-Shell-script-*-
#
# requires:
#   bash
#

function ssh() {
  $(which ssh) -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' $@
}

function remove_ssh_known_host_entry() {
  local ipaddr=$1
  ssh-keygen -R ${ipaddr} >/dev/null 2>&1
}

function setup_ssh_key_pair() {
  local output_keyfile=$1; shift; eval local $@
  [[ -f ${output_keyfile} ]] || ssh-keygen -N "" -f ${output_keyfile} -C ${output_keyfile}
}

function teardown_ssh_key_pair() {
  local output_keyfile=$1
  [[ -f ${output_keyfile} ]] || return 0
  rm -f ${output_keyfile}*
}
