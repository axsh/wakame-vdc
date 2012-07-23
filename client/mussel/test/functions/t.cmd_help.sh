#!/bin/bash

. ../../functions

test_cmd_help() {
  assertEquals \
   "`cmd_help command sub-commands 2>&1`" \
          "$0 command [help|sub-commands]"
}

. ../shunit2
