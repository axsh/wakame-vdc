#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=load_balancer

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf

  balance_algorithm=
  cookie_name=
  display_name=
  engine=
  instance_port=
  max_connection=
  port=
  private_key=
  protocol=
  public_key=
}

### index

function test_load_balancer_index_stateless() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)"
}

function test_load_balancer_index_stateful() {
  local cmd=index
  local state=running

  assertEquals "$(cli_wrapper ${namespace} ${cmd} --state=${state})" \
               "curl -X GET $(base_uri)/${namespace}s.$(suffix)?state=${state}"
}

### create

function test_load_balancer_create_no_opts() {
  local cmd=create

  local balance_algorithm=leastconn
  local cookie_name=shunit2_cookie
  local display_name=shunit_disp
  local engine=haproxy
  local httpchk_path="/index.html"
  local instance_port=80
  local max_connection=1000
  local port=80
  local private_key=prv
  local protocol=http
  local public_key=pub

  local opts=""

  local params="
    balance_algorithm=${balance_algorithm}
    cookie_name=${cookie_name}
    display_name=${display_name}
    engine=${engine}
    httpchk_path=${httpchk_path}
    instance_port=${instance_port}
    max_connection=${max_connection}
    port[]=${port}
    private_key=${private_key}
    protocol[]=${protocol}
    public_key=${public_key}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"
}

function test_load_balancer_create_opts() {
  local cmd=create

  local balance_algorithm=leastconn
  local cookie_name=shunit2_cookie
  local display_name=shunit_disp
  local engine=haproxy
  local httpchk_path="/index.html"
  local instance_port=80
  local max_connection=1000
  local port=80
  local private_key=prv
  local protocol=http
  local public_key=pub

  local opts="
    --balance-algorithm=${balance_algorithm}
    --cookie-name=${cookie_name}
    --display-name=${display_name}
    --engine=${engine}
    --httpchk-path=${httpchk_path}
    --instance-port=${instance_port}
    --max-connection=${max_connection}
    --port=${port}
    --private-key=${private_key}
    --protocol=${protocol}
    --public-key=pub=${public_key}
  "

  local params="
    balance_algorithm=${balance_algorithm}
    cookie_name=${cookie_name}
    display_name=${display_name}
    engine=${engine}
    httpchk_path=${httpchk_path}
    instance_port=${instance_port}
    max_connection=${max_connection}
    port[]=${port}
    private_key=${private_key}
    protocol[]=${protocol}
    public_key=${public_key}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) $(base_uri)/${namespace}s.$(suffix)"

}

### xcreate

function test_load_balancer_xcreate() {
  local cmd=xcreate

  local balance_algorithm=leastconn
  local cookie_name=
  local display_name=
  local engine=haproxy
  local httpchk_path="/index.html"
  local instance_port=80
  local max_connection=1000
  local port=80
  local private_key=
  local protocol=http
  local public_key=

  local MUSSEL_CUSTOM_DATA="
    balance_algorithm=${balance_algorithm}
    cookie_name=${cookie_name}
    display_name=${display_name}
    engine=${engine}
    httpchk_path=${httpchk_path}
    instance_port=${instance_port}
    max_connection=${max_connection}
    port=${port}
    private_key=${private_key}
    protocol=${protocol}
    public_key=${public_key}
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) $(base_uri)/${namespace}s.$(suffix)"
}

### poweron

function test_load_balancer_poweron() {
  local cmd=poweron

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

### poweroff

function test_load_balancer_poweroff() {
  local cmd=poweroff

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X PUT $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)"
}

## shunit2

. ${shunit2_file}
