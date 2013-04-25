#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=network_vif

## functions

### help

function test_network_vif_help_stderr_to_stdout_success() {
  extract_args ${namespace} help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 ${namespace} [help|attach_external_ip|destroy|detach_external_ip|index|show|show_external_ip|xcreate]"
}

## shunit2

. ${shunit2_file}
