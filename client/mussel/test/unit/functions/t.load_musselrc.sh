#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

function setUp() {
  musselrc_path=${BASH_SOURCE[0]%/*}/musselrc.$$
  musselrc_system_path=${BASH_SOURCE[0]%/*}/musselrc_system.$$

  DCMGR_HOST=
  DCMGR_PORT=
  MUSSEL_RC=/dev/null
  MUSSEL_RC_SYSTEM=/dev/null

  dcmgr_host=192.0.2.10
  dcmgr_port=9001

  cat <<-EOS > ${musselrc_path}
	DCMGR_HOST=${dcmgr_host}
	DCMGR_PORT=${dcmgr_port}
	EOS

  cat <<-EOS > ${musselrc_system_path}
	DCMGR_HOST=${dcmgr_host}
	DCMGR_PORT=${dcmgr_port}
	EOS
}

function tearDown() {
  rm -f ${musselrc_path}
  rm -f ${musselrc_system_path}
}

function test_load_musselrc() {
  load_musselrc
  assertEquals 0 $?

  assertEquals "${DCMGR_HOST}" ""
  assertEquals "${DCMGR_PORT}" ""
}

function test_load_musselrc_defined_rcfile_path() {
  MUSSEL_RC=${musselrc_path}

  load_musselrc
  assertEquals 0 $?

  assertEquals "${DCMGR_HOST}" "${dcmgr_host}"
  assertEquals "${DCMGR_PORT}" "${dcmgr_port}"
}

## shunit2

. ${shunit2_file}
