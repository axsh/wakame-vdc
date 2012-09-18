#!/bin/bash

. ../../functions
. ./helper_shunit2


setUp() {
  xquery=
  state=
}

test_load_balancer_help_stderr_to_devnull_success() {
  extract_args load_balancer help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>/dev/null)
  assertEquals "${res}" ""
}

test_load_balancer_help_stderr_to_stdout_success() {
  extract_args load_balancer help
  res=$(run_cmd  ${MUSSEL_ARGS} 2>&1)
  assertEquals "${res}" "$0 load_balancer [help|index|show|create|destroy|poweroff|poweron]"
}

test_load_balancer_state() {
  extract_args load_balancer index --state=running
  assertEquals "${state}" "running"
}

test_load_balancer_create() {
  extract_args load_balancer create
  run_cmd ${MUSSEL_ARGS}
}

. ../shunit2
