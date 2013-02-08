#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

## functions

#
# MUSSEL_LOGLEVEL:debug
#
test_shlog_MUSSEL_LOGLEVEL_debug_success() {
  assertEquals \
   "`MUSSEL_LOGLEVEL=debug shlog echo hello`" \
        "${MUSSEL_PROMPT} echo hello
hello"
}

test_shlog_MUSSEL_LOGLEVEL_debug_fail() {
  assertNotEquals \
   "`MUSSEL_LOGLEVEL=debug shlog typo hello 2>/dev/null`" \
        "${MUSSEL_PROMPT} typo hello
hello"
}


#
# MUSSEL_LOGLEVEL:info
#
test_shlog_MUSSEL_LOGLEVEL_info_success() {
  local cmd="echo hello"
  assertEquals \
   "`MUSSEL_LOGLEVEL=info shlog ${cmd}`" \
                         "hello"
}

test_shlog_MUSSEL_LOGLEVEL_info_fail() {
  local cmd="echo hello"
  assertNotEquals \
   "`MUSSEL_LOGLEVEL=info shlog ${cmd}`" \
       "${MUSSEL_PROMPT} ${cmd}\n${cmd}"
}

#
# MUSSEL_LOGLEVEL:empty
#
test_shlog_MUSSEL_LOGLEVEL_empty_success() {
  local cmd="echo hello"
  assertEquals \
   "`MUSSEL_LOGLEVEL= shlog ${cmd}`" "hello"
}

test_shlog_MUSSEL_LOGLEVEL_empty_fail() {
  local cmd="echo hello"
  assertNotEquals \
   "`MUSSEL_LOGLEVEL= shlog ${cmd}`" \
   "${MUSSEL_PROMPT} ${cmd}\n${cmd}"
}

#
# command not found
#
test_shlog_command_not_found_success() {
  `shlog typo hello 2>/dev/null`
  assertNotEquals $? 0
}

#
# dry-run mode
#
test_shlog_dryrun_MUSSEL_LOGLEVEL_default() {
  assertEquals "`MUSSEL_DRY_RUN=on           shlog date`" ""
  assertEquals "`MUSSEL_DRY_RUN=on MUSSEL_LOGLEVEL= shlog date`" ""
}
test_shlog_dryrun_MUSSEL_LOGLEVEL_debug_on() {
  assertEquals \
   "`MUSSEL_DRY_RUN=on MUSSEL_LOGLEVEL=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_MUSSEL_LOGLEVEL_debug_y() {
  assertEquals \
   "`MUSSEL_DRY_RUN=y MUSSEL_LOGLEVEL=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_MUSSEL_LOGLEVEL_debug_yes() {
  assertEquals \
   "`MUSSEL_DRY_RUN=yes MUSSEL_LOGLEVEL=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_MUSSEL_LOGLEVEL_debug_on() {
  assertEquals \
   "`MUSSEL_DRY_RUN=on MUSSEL_LOGLEVEL=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_MUSSEL_LOGLEVEL_debug_1() {
  assertEquals \
   "`MUSSEL_DRY_RUN=1 MUSSEL_LOGLEVEL=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}

## shunit2

. ${shunit2_file}
