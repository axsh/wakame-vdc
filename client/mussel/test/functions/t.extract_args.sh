#!/bin/bash

. ../../functions


test_extract_args_commands_success() {
  local opts="a b c d"
  extract_args ${opts}
  assertEquals "${opts}" "${MUSSEL_ARGS}"
}

test_extract_args_options_success() {
  local commands="command sub-command"
  local options="--key0=value0 --key1=value1"
  local opts="${commands} ${options}"
  extract_args ${opts}
  assertEquals "${commands}" "${MUSSEL_ARGS}"
}

. ../shunit2
