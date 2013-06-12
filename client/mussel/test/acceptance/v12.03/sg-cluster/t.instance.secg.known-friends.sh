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
known_ipaddrs=

## functions

function before_create_instance() {
  # don't clear ssh_key_pair_uuid= to apply same keypair to instances
  # don't clear security_group_uuid= to apploy same security-gorup to instances
  instance_uuid=
}

### step

function test_ping_to_known_instances() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    known_ipaddrs="${known_ipaddrs} $(cached_instance_param ${instance_uuid} | hash_value address)"
  done

  for instance_uuid in $(cat ${instance_uuids_path}); do
    run_cmd instance show ${instance_uuid} | grep -- '- sg-'

    instance_ipaddr=$(cached_instance_param ${instance_uuid} | hash_value address)
    for known_ipaddr in ${known_ipaddrs}; do
      [[ ${instance_ipaddr} == ${known_ipaddr} ]] && continue
      ssh ${ssh_user}@${instance_ipaddr} -i ${ssh_key_pair_path} "ping -c 1 -W 3 ${known_ipaddr}"
      assertEquals $? 0
    done
  done
}

## shunit2

. ${shunit2_file}
