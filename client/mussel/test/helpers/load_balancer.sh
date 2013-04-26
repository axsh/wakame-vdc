#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare load_balancer_uuid

## variables

declare instance_uuid

### required

balance_algorithm=${balance_algorithm:-leastconn}
cookie_name=${cookie_name:-shunit2cookie}
engine=${engine:-haproxy}
instance_port=${instance_port:-80}
instance_protocol=${instance_protocol:-http}
max_connection=${max_connection:-1000}
port=${port:-80}
protocol=${protocol:-http}

### optional

allow_list=${allow_list:-}
instance_spec_id=${instance_spec_id:-}
description=${description:-}
private_key=${private_key:-}
public_key=${public_key:-}
httpchk=${httpchk:-}

### cookie file

cookie_path=$(generate_cache_file_path cookie)

## functions

### load_balancer

function _create_load_balancer() {
  local create_output="$(run_cmd load_balancer create)"
  echo "${create_output}"

  load_balancer_uuid=$(echo "${create_output}" | hash_value id)
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
}

function _destroy_load_balancer() {
  run_cmd load_balancer destroy ${load_balancer_uuid}
  retry_until "document_pair? load_balancer ${load_balancer_uuid} state terminated"
}

#### load_balancer hooks

function  before_create_load_balancer() { :; }
function   after_create_load_balancer() { :; }
function before_destroy_load_balancer() { :; }
function  after_destroy_load_balancer() { :; }

function create_load_balancer() {
  before_create_load_balancer
        _create_load_balancer
   after_create_load_balancer
}
function destroy_load_balancer() {
  before_destroy_load_balancer
        _destroy_load_balancer
   after_destroy_load_balancer
}
