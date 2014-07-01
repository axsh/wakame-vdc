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

port="443"
protocol="https"
load_balancer_private_key=$(ssl_output_dir)/${common_name}.key.pem
load_balancer_public_key=$(ssl_output_dir)/${common_name}.crt.pem

target_instance_num=${target_instance_num:-1}

## functions

### step

function test_register_instances_to_load_balancer() {
  vifs="$(cat ${instance_vifs_path})" run_cmd load_balancer register ${load_balancer_uuid}
  assertEquals 0 $?

  retry_until "curl -fsSkL https://${load_balancer_ipaddr}/"
  assertEquals 0 $?
}

function test_https_get_for_registerd_lb() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    retry_until [[ '"$(curl -fsSkL https://${load_balancer_ipaddr}/)"' == "${instance_uuid}" ]]
    local return_code=$?
    assertEquals 0 ${return_code}
  done
}

function test_http_header() {
  local lbnode_env=$(curl -fsSkL https://${load_balancer_ipaddr}/cgi-bin/env.cgi)
  assertEquals ${DCMGR_CLIENT_ADDR} $(echo "${lbnode_env}" | grep HTTP_X_FORWARDED_FOR | cut -d "=" -f 2)
  assertEquals "https" $(echo "${lbnode_env}" | grep HTTP_X_FORWARDED_PROTO | cut -d "=" -f 2)
}

function test_unregister_instances_from_load_balancer() {
  vifs="$(cat ${instance_vifs_path})" run_cmd load_balancer unregister ${load_balancer_uuid}
  assertEquals 0 $?

  retry_while "curl -fsSkL https://${load_balancer_ipaddr}/"
  assertEquals 0 $?
}

function test_https_get_for_unregisterd_lb() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    retry_while [[ '"$(curl -fsSkL https://${load_balancer_ipaddr}/)"' == "${instance_uuid}" ]]
    assertEquals 0 $?
  done
}

## shunit2

. ${shunit2_file}
