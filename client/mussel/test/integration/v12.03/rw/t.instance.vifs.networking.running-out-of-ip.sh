#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

network_id="nw-minimum"
test_case_instance_uuid=

## functions

function needs_vif() { true; }

function needs_secg() { true; }

function tearDown() {
  # ensure termination of the instance
  run_cmd instance destroy ${test_case_instance_uuid}
  retry_until "document_pair? instance ${test_case_instance_uuid} state terminated"
}

###

function render_vif_table() {
  cat <<-EOS
	{
	"eth0":{"index":"0","network":"${network_id}","security_groups":"${security_group_uuid}"}
	}
	EOS
}

function test_create_instance_with_netwrok_running_out_of_ip() {
  test_case_instance_uuid=$(run_cmd instance create | hash_value id)

  retry_until "document_pair? instance ${test_case_instance_uuid} state terminated"

  assertEquals "instance should be terminated" 0 $?

}

## shunit2

. ${shunit2_file}
