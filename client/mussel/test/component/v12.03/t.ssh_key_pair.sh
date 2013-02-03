#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ssh_key_pair

## functions

function setUp() {
  xquery=
  state=
  uuid=asdf
}

### index

function test_ssh_key_pair_index() {
  local cmd=index
  assertEquals "$(cli_wrapper ${namespace} ${cmd})" \
               "curl -X GET ${base_uri}/${namespace}s.${format}?"
}

### show

function test_ssh_key_pair_show() {
  local cmd=show

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X GET ${base_uri}/${namespace}s/${uuid}.${format}"
}

### destroy

function test_ssh_key_pair_destroy() {
  local cmd=destroy

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${uuid})" \
               "curl -X DELETE ${base_uri}/${namespace}s/${uuid}.${format}"
}

### xcreate

function test_ssh_key_pair_xcreate() {
  local cmd=xcreate

  local MUSSEL_CUSTOM_DATA="
    name=shunit2
  "

  assertEquals "$(MUSSEL_CUSTOM_DATA=$(urlencode_data ${MUSSEL_CUSTOM_DATA}) cli_wrapper ${namespace} ${cmd})" \
               "curl -X POST $(urlencode_data ${MUSSEL_CUSTOM_DATA}) ${base_uri}/${namespace}s.${format}"
}

### create

function test_ssh_key_pair_create_no_opts() {
  local cmd=create

  local description=shunit2
  local display_name=foo
  local download_once=
  local public_key=

  local opts=""

  local params="
    description=${description}
    display_name=${display_name}
    download_once=${download_once}
    public_key=${public_key}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

function test_ssh_key_pair_create_opts() {
  local cmd=create

  local description=shunit2
  local display_name=foo
  local download_once=
  local public_key=

  local opts="
    --description=${description}
    --display-name=${display_name}
    --download-once=${download_once}
    --public-key=${public_key}
  "

  local params="
    description=${description}
    display_name=${display_name}
    download_once=${download_once}
    public_key=${public_key}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
