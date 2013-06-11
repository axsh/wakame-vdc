#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables

common_name=example.com
private_key=$(ssl_output_dir)/${common_name}.key.pem
public_key=$(ssl_output_dir)/${common_name}.crt.pem

### optional

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
  destroy_load_balancer
  teardown_self_signed_key ${common_name}
}

###

function test_create_load_balancer_multiple_protocol_port() {
  load_balancer_uuid="$(protocol="http https" port="80 443" run_cmd load_balancer create | hash_value id)"
  assertNotNull "load_balancer_uuid should not be null" "${load_balancer_uuid}"

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
