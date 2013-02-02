#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare namespace=load_balancer

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_load_balancer_index_stateless() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

function test_load_balancer_index_stateful() {
  local cmd=index
  local state=running

  assertEquals "$(cli_wrapper ${namespace} ${cmd} --state=${state})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?state=${state}"
}

### show

function test_load_balancer_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_load_balancer_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

### create

function test_load_balancer_create_no_opts() {
  local cmd=create

  local protocol=http
  local balancer_port=80
  local instance_port=80
  local balance_algorithm=leastconn
  local max_connection=1000

  local display_name=
  local cookie_name=
  local private_key=
  local public_key=

  local opts=""

  local params="
    display_name=${display_name}
    protocol=${protocol}
    port=${balancer_port}
    instance_port=${instance_port}
    balance_algorithm=${balance_algorithm}
    engine=haproxy
    cookie_name=${cookie_name}
    private_key=${private_key}
    public_key=${public_key}
    engine=haproxy
    max_connection=${max_connection}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_load_balancer_create_opts() {
  local cmd=create

  local protocol=http
  local balancer_port=80
  local instance_port=80
  local balance_algorithm=leastconn
  local max_connection=1000

  local display_name=
  local cookie_name=
  local private_key=
  local public_key=

  local opts="
    --protocol=${protocol}
    --balancer-port=${balancer_port}
    --instance-port=${instance_port}
    --balance-algorithm=${balance_algorithm}
    --max-connection=${max_connection}
    --display-name=${display_name}
    --cookie-name=${cookie_name}
    --private-key=${private_key}
  "

  local params="
    display_name=${display_name}
    protocol=${protocol}
    port=${balancer_port}
    instance_port=${instance_port}
    balance_algorithm=${balance_algorithm}
    engine=haproxy
    cookie_name=${cookie_name}
    private_key=${private_key}
    public_key=${public_key}
    engine=haproxy
    max_connection=${max_connection}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

### xcreate

function test_load_balancer_xcreate() {
  local cmd=xcreate

  local protocol=http
  local balancer_port=80
  local instance_port=80
  local balance_algorithm=leastconn
  local max_connection=1000

  local display_name=
  local cookie_name=
  local private_key=
  local public_key=

  local MUSSEL_CUSTOM_DATA="
    display_name=${display_name}
    protocol=${protocol}
    port=${balancer_port}
    instance_port=${instance_port}
    balance_algorithm=${balance_algorithm}
    engine=haproxy
    cookie_name=${cookie_name}
    private_key=${private_key}
    public_key=${public_key}
    engine=haproxy
    max_connection=${max_connection}
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

### poweron

function test_load_balancer_poweron() {
  local cmd=poweron

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

### poweroff

function test_load_balancer_poweroff() {
  local cmd=poweroff

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT -d ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}"
}

## shunit2

. ${shunit2_file}
