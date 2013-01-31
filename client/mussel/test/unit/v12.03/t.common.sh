#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

# known resources
function test_common_known_resource_index_success() {
  for resource in ${MUSSEL_RESOURCES}; do
    xquery=
    extract_args ${resource} index
    run_cmd ${MUSSEL_ARGS}
    assertEquals $? 0
  done
}

function test_common_known_resource_show_success() {
  for resource in ${MUSSEL_RESOURCES}; do
    extract_args ${resource} show asdf
    run_cmd ${MUSSEL_ARGS}
    assertEquals $? 0
  done
}

# unknown resources
function test_common_unknown_resource_index_fail() {
  for resource in ${MUSSEL_RESOURCES}; do
    xquery=
    # add "_" to resource prefix
    extract_args _${resource} index
    loglevel=debug run_cmd ${MUSSEL_ARGS} 2>/dev/null
    assertNotEquals $? 0
  done
}

## shunit2

. ${shunit2_file}
