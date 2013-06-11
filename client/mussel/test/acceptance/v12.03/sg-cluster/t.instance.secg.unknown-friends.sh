#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

target_instance_num=${target_instance_num:-3}
unknown_ipaddrs=

## functions

function before_create_instance() {
  # don't clear ssh_key_pair_uuid= to apply same keypair to instances
  instance_uuid= security_group_uuid=
}

### step

function test_ping_to_unknown_instances() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    unknown_ipaddrs="${unknown_ipaddrs} $(cached_instance_param ${instance_uuid} | hash_value address)"
  done

  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr=$(cached_instance_param ${instance_uuid} | hash_value address)
    for unknown_ipaddr in ${unknown_ipaddrs}; do
      [[ ${instance_ipaddr} == ${unknown_ipaddr} ]] && continue
      ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${unknown_ipaddr}"
      assertNotEquals $? 0
    done
  done
}

## shunit2

. ${shunit2_file}
