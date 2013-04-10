#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_load_balancer.sh

## variables
httpchk=${httpchk:-}
httpchk_path=${httpchk_path:-${BASH_SOURCE[0]%/*}/httpchk.$$}

### optional

## functions

function render_httpchk_table() {
  cat <<-EOS
	{"path":"/index.html"}
	EOS
}

function oneTimeSetUp() {
  :
}

function oneTimeTearDown() {
  :
}

function setUp() {
  render_httpchk_table > ${httpchk_path}
  httpchk=${httpchk_path} 
}

function tearDown() {
  rm -f ${httpchk_path}
  destroy_load_balancer
}

###

function test_create_load_balancer_httpchk() {

  load_balancer_uuid="$(run_cmd load_balancer create | hash_value id)"
  assertEquals $? 0

  retry_until "document_pair? load_balancer ${load_balancer_uuid} state running"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
