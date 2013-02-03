#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ssh_key_pair
declare public_key_file=${BASH_SOURCE[0]%/*}/public_key_file.$$.txt

## functions

function setUp() {
  cat <<-EOS > ${public_key_file}
	ASDFASDF
	ASDFASDF
	EOS
}

function tearDown() {
  rm -f ${public_key_file}
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

function test_ssh_key_pair_create_opts_public_key_file() {
  local cmd=create

  local description=shunit2
  local display_name=foo
  local download_once=
  local public_key=${public_key_file}

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
    public_key@${public_key}
  "

  assertEquals "$(cli_wrapper ${namespace} ${cmd} ${opts})" \
               "curl -X POST $(urlencode_data ${params}) ${base_uri}/${namespace}s.${format}"
}

## shunit2

. ${shunit2_file}
