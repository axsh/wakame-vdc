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

function test_update_load_balancer_multiple_listen() {
  load_balancer_uuid="$(run_cmd load_balancer create | hash_value id)"
  assertNotNull "load_balancer_uuid should not be null" "${load_balancer_uuid}"

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"

  inbounds_port="$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value port)"
  assertEquals "${inbounds_port}" "80"

  port="80 443" protocol="http https" run_cmd load_balancer update ${load_balancer_uuid}

expected="80
443"
  inbounds_port="$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value port)"
  assertEquals "${inbounds_port}" "${expected}"

expected="http
https"
  inbounds_protocol="$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value protocol)"
  assertEquals "${inbounds_protocol}" "${expected}"
}

## shunit2

. ${shunit2_file}
