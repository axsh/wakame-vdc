#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

### optional

common_name=example.com
private_key=$(ssl_output_dir)/${common_name}.key.pem
public_key=$(ssl_output_dir)/${common_name}.crt.pem

## functions

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

function setUp() {
  setup_self_signed_key ${common_name}
}

function tearDown() {
  teardown_self_signed_key ${common_name}
  destroy_load_balancer
}

###

function test_create_load_balancer_https() {
  load_balancer_uuid="$(port=443 protocol=https instance_protocol=http private_key=${private_key} public_key=${public_key} \
   run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

function test_create_load_balancer_ssl() {
  load_balancer_uuid="$(port=443 protocol=ssl instance_protocol=tcp private_key=${private_key} public_key=${public_key} \
   run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
