#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=ip_pool

## functions

### help

function test_ip_pool_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|acquire|create|destroy|index|ip_handles|release|show|xcreate]"
}

## shunit2

. ${shunit2_file}
