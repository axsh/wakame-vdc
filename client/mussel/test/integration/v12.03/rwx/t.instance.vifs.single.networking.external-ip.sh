#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_instance_vifs_single.sh

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
ip_pool_id=${ip_pool_id:-ipp-external}
ip_handle_id=
network_vif_id=

## functions

function needs_vif() { true; }

###

function test_show_instance_vifs_single_networking_external_ip() {
  local external_ip=$(run_cmd network_vif show_external_ip ${network_vif_id} | hash_value ipv4)
  echo "external_ip: $external_ip"
  assertTrue "[ -n ${external_ip} ]"
}

function after_create_instance() {
  ip_handle_id=$(acquire_external_ip ${ip_pool_id} ${vifs_eth0_network_id})
  network_vif_id=$(cached_instance_param ${instance_uuid} | hash_value vif_id)
  attach_external_ip ${network_vif_id}
}

function before_destroy_instance() {
  detach_external_ip ${network_vif_id} ${ip_handle_id}
  release_external_ip ${ip_pool_id} ${ip_handle_id}
}

## shunit2

. ${shunit2_file}
