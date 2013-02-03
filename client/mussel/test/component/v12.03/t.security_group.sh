#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=security_group
declare rule_file=${BASH_SOURCE[0]%/*}/rule.$$.txt

## functions

function setUp() {
  cat <<-EOS > ${rule_file}
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	tcp:80,80,ip4:0.0.0.0/0
	EOS
}

function tearDown() {
  rm -f ${rule_file}
}

### create

function test_security_group_create_no_opts() {
  local cmd=create

  local service_type=std
  local rule=tcp:22,22,ip4:0.0.0.0/0
  local description=shunit2
  local display_name=foo

  local opts=""

  local params="
    service_type=${service_type}
    rule=${rule}
    description=${description}
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_security_group_create_opts() {
  local cmd=create

  local service_type=std
  local rule=tcp:22,22,ip4:0.0.0.0/0
  local description=shunit2
  local display_name=foo

  local opts="
    --service-type=${service_type}
    --rule=${rule}
    --description=${description}
    --display-name=${display_name}
  "

  local params="
    service_type=${service_type}
    rule=${rule}
    description=${description}
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_security_group_create_opts_rule_file() {
  local cmd=create

  local service_type=std
  local rule=${rule_file}
  local description=shunit2
  local display_name=foo

  local opts=""

  local params="
    service_type=${service_type}
    rule@${rule}
    description=${description}
    display_name=${display_name}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
