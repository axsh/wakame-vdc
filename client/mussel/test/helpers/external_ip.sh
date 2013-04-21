#!/bin/bash
#
# requires:
#   bash
#

## variables

declare ip_handle_id
declare external_ip

function acquire_external_ip() {
  local ip_pool_id=$1
  local network_id=$2
  local create_output="$(run_cmd ip_pool acquire ${ip_pool_id})"
  ip_handle_id=$(echo "${create_output}" | hash_value ip_handle_id)
  echo ${ip_handle_id}
}

function release_external_ip() {
  local ip_pool_id=$1
  local ip_handle_id=$2
  run_cmd ip_pool release ${ip_pool_id}
}

function attach_external_ip() {
  network_vif_id=$1
  local create_output="$(run_cmd network_vif attach_external_ip ${network_vif_id})"
  external_ip=$(echo "${create_output}" | hash_value external_ip)
  echo ${external_ip}
}

function detach_external_ip() {
  local network_vif_id=$1
  local ip_handle_id=$2
  local create_output="$(run_cmd network_vif detach_external_ip ${network_vif_id})"
}
