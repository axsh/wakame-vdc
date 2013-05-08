#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer_with_registered_instances.sh

## variables

port="443"
protocol="https"
load_balancer_private_key=$(ssl_output_dir)/${common_name}.key.pem
load_balancer_public_key=$(ssl_output_dir)/${common_name}.crt.pem

target_instance_num=${target_instance_num:-3}
repeat_count=5

## functions

### step

function test_sticky_session() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    retry_until [[ '"$(curl -fsSkL https://${load_balancer_ipaddr}/)"' == "${instance_uuid}" ]]
    assertEquals $? 0
  done

  local expected_instance_uuid=$(curl -fsSkL -c ${cookie_path} https://${load_balancer_ipaddr}/)
  echo "expected_instance_uuid: ${expected_instance_uuid}"

  for i in $(seq 1 ${repeat_count}); do
    sleep 1
    local actual_instance_uuid=$(curl -fsSkL -b ${cookie_path} https://${load_balancer_ipaddr}/)
    echo "${i}. actual_instance_uuid: ${actual_instance_uuid}"
    assertEquals "should be the same uuid" ${expected_instance_uuid} ${actual_instance_uuid}
  done
}

function test_balance_algorithm_source() {
  balance_algorithm="source" run_cmd load_balancer update ${load_balancer_uuid}
  sleep 1

  local expected_instance_uuid=$(curl -fsSkL https://${load_balancer_ipaddr}/)
  echo "expected_instance_uuid: ${expected_instance_uuid}"

  for i in $(seq 1 ${repeat_count}); do
    sleep 1
    local actual_instance_uuid=$(curl -fsSkL https://${load_balancer_ipaddr}/)
    echo "${i}. actual_instance_uuid: ${actual_instance_uuid}"
    assertEquals "should be the same uuid" ${expected_instance_uuid} ${actual_instance_uuid}
  done
}

function test_balance_algorithm_leastconn() {
  balance_algorithm="leastconn" run_cmd load_balancer update ${load_balancer_uuid}
  sleep 1

  trap "kill -9 ${pids} 2>/dev/null" ERR

  for i in $(seq 1 $((${target_instance_num} - 1))); do
    curl -fsSkL https://${load_balancer_ipaddr}/cgi-bin/sleep.cgi > /dev/null 2>&1 &
    pids="${pids} $!"
  done

  local expected_instance_uuid=$(curl -fsSkL -c ${cookie_path} https://${load_balancer_ipaddr}/)
  echo "expected_instance_uuid: ${expected_instance_uuid}"

  for i in $(seq 1 ${repeat_count}); do
    sleep 1
    local actual_instance_uuid=$(curl -fsSkL https://${load_balancer_ipaddr}/)
    echo "${i}. actual_instance_uuid: ${actual_instance_uuid}"
    assertEquals "should be the same uuid" ${expected_instance_uuid} ${actual_instance_uuid}
  done

  kill -9 ${pids} 2>/dev/null
}

function setUp() {
  balance_algorithm="leastconn" run_cmd load_balancer update ${load_balancer_uuid}
  sleep 1
}

## shunit2

. ${shunit2_file}
