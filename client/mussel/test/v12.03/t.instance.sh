#!/bin/bash

. ../../functions
. ./helper_shunit2


setUp() {
  xquery=
  state=
}

test_instance_state() {
  extract_args instance index --state=running
  assertEquals "${state}" "running"
}

test_instance_create() {
  extract_args instance create
  run_cmd ${MUSSEL_ARGS}
}

. ../shunit2
