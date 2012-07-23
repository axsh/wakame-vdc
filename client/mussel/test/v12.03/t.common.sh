#!/bin/bash

. ../../functions
. ./helper_shunit2


# known resources
test_common_known_resource_index_success() {
  for resource in ${MUSSEL_RESOURCES}; do
    xquery=
    extract_args ${resource} index
    run_cmd ${MUSSEL_ARGS}
    assertEquals $? 0
  done
}

test_common_known_resource_show_success() {
  for resource in ${MUSSEL_RESOURCES}; do
    extract_args ${resource} show asdf
    run_cmd ${MUSSEL_ARGS}
    assertEquals $? 0
  done
}

# unknown resources
test_common_unknown_resource_index_fail() {
  for resource in ${MUSSEL_RESOURCES}; do
    xquery=
    # add "_" to resource prefix
    extract_args _${resource} index
    loglevel=debug run_cmd ${MUSSEL_ARGS} 2>/dev/null
    assertNotEquals $? 0
  done
}

. ../shunit2
