#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

target_instance_num=${target_instance_num:-1}
client_ipaddr=${client_ipaddr:-10.0.2.2}

## functions

### step

function test_register_instances_to_load_balancer() {
  vifs="$(cat ${instance_vifs_path})" run_cmd load_balancer register ${load_balancer_uuid}
  assertEquals $? 0

  retry_until "curl -fsSkL http://${load_balancer_ipaddr}/"
  assertEquals $? 0
}

function test_http_get_for_registerd_lb() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    retry_until [[ '"$(curl -fsSkL http://${load_balancer_ipaddr}/)"' == "${instance_uuid}" ]]
    assertEquals $? 0
  done
}

function test_http_header() {
  lcoal lbnode_env=$(curl -fsSkL http://${load_balancer_ipaddr}/cgi-bin/env.cgi)
  assertEquals ${client_ipaddr} $(echo "${lbnode_env}" | grep HTTP_X_FORWARDED_FOR)
  assertEquals "http" $(echo "${lbnode_env}" | grep HTTP_X_FORWARDED_PROTO)
}

function test_unregister_instances_from_load_balancer() {
  vifs="$(cat ${instance_vifs_path})" run_cmd load_balancer unregister ${load_balancer_uuid}
  assertEquals $? 0

  retry_while "curl -fsSkL http://${load_balancer_ipaddr}/"
  assertEquals $? 0
}

function test_http_get_for_unregisterd_lb() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    retry_while [[ '"$(curl -fsSkL http://${load_balancer_ipaddr}/)"' == "${instance_uuid}" ]]
    assertEquals $? 0
  done
}

## shunit2

. ${shunit2_file}
