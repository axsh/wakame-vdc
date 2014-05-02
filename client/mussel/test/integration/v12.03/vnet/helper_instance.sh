#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_uuids_path=$(generate_cache_file_path instance_uuids)

## functions

### instance

function oneTimeSetUp() {
  # launching instances
  for i in $(eval echo "{1..${target_instance_num:-1}}"); do
    instance_uuid=i-vm${i}
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
  done

  # wait until the instance be ready
  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr="$(cached_instance_param ${instance_uuid} | hash_value address)"
    wait_for_network_to_be_ready ${instance_ipaddr}
    wait_for_port_to_be_ready    ${instance_ipaddr} tcp ${instance_port}
  done
}

function oneTimeTearDown() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    destroy_instance
  done
  rm -f ${instance_uuids_path}
}
