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

## functions

### shunit2 setup

function oneTimeSetUp() {
  create_instance
  create_load_balancer

  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  load_balancer_ipaddr=$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value address | head -1)
  instance_vifs="$(run_cmd instance show ${instance_uuid} | hash_value vif_id)"

  wait_for_network_to_be_ready ${instance_ipaddr}
  wait_for_network_to_be_ready ${load_balancer_ipaddr}

  wait_for_httpd_to_be_ready ${instance_ipaddr}
  wait_for_httpd_to_be_ready ${load_balancer_ipaddr}
}

function oneTimeTearDown() {
  destroy_instance
  destroy_load_balancer
}

### step

function test_register_instances_to_load_balancer() {
  vifs=${instance_vifs} run_cmd load_balancer register ${load_balancer_uuid}
  assertEquals $? 0

  retry_until "curl -fsSkL http://${load_balancer_ipaddr}/"
}

function test_http_get_for_registerd_lb() {
  assertEquals \
    "${instance_uuid}" \
    "$(curl -fsSkL http://${load_balancer_ipaddr}/)"
}

function test_unregister_instances_from_load_balancer() {
  vifs=${instance_vifs} run_cmd load_balancer unregister ${load_balancer_uuid}
  assertEquals $? 0

  retry_while "curl -fsSkL http://${load_balancer_ipaddr}/"
}

function test_http_get_for_unregisterd_lb() {
  assertNotEquals \
    "${instance_uuid}" \
    "$(curl -fsSkL http://${load_balancer_ipaddr}/)"
}

## shunit2

. ${shunit2_file}
