#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

vifs_eth0_network_id=${vifs_eth0_network_id:-nw-demo1}
ip_pool_id=${ip_pool_id:-ipp-external}
ip_handle_id=
network_vif_id=

## functions

### load_balancer

function test_show_load_balancer_external_ip() {
  local external_ip=$(run_cmd network_vif show_external_ip ${network_vif_id} | hash_value ipv4)
  echo "external_ip: $external_ip"
  assertTrue "[ -n ${external_ip} ]"
}

function after_create_load_balancer() {
  ip_handle_id=$(acquire_external_ip ${ip_pool_id} ${vifs_eth0_network_id})
  network_vif_id=$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value vif_id)
  attach_external_ip ${network_vif_id}
}

function before_destroy_load_balancer() {
  detach_external_ip ${network_vif_id} ${ip_handle_id}
  release_external_ip ${ip_pool_id} ${ip_handle_id}
}

## shunit2

. ${shunit2_file}
