#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare instance_ipaddr=
declare instance_uuids_path=$(generate_cache_file_path instance_uuids)

function needs_vif() { true; }

## functions

### instance

function oneTimeSetUp() {
  # launching instances
  for i in $(eval echo "{1..${target_instance_num:-1}}"); do
    create_instance
    echo ${instance_uuid} >> ${instance_uuids_path}
  done

  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr="$(cached_instance_param ${instance_uuid} | hash_value address)"

    # wait until the instance be ready
    wait_for_network_to_be_ready ${instance_ipaddr}
    wait_for_port_to_be_ready    ${instance_ipaddr} tcp ${instance_port}

    # configure eth0
    ssh root@${instance_ipaddr} -i ${ssh_key_pair_path} "
      rm -rf /etc/sysconfig/network-scripts/ifcfg-eth0
      cat 'DEVICE=eth0' >> /etc/sysconfig/network-scripts/ifcfg-eth0
      cat 'TYPE=Ethernet' >> /etc/sysconfig/network-scripts/ifcfg-eth0
      cat 'BOOTPROTO=dhcp' >> /etc/sysconfig/network-scripts/ifcfg-eth0
      cat 'ONBOOT=yes' >> /etc/sysconfig/network-scripts/ifcfg-eth0
      service network restart
    "
  done
}

function oneTimeTearDown() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    destroy_instance
  done
  rm -f ${instance_uuids_path}
}
