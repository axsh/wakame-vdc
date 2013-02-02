#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

#
# loglevel:debug
#
test_shlog_loglevel_debug_success() {
  assertEquals \
   "`loglevel=debug shlog echo hello`" \
        "${MUSSEL_PROMPT} echo hello
hello"
}

test_shlog_loglevel_debug_fail() {
  assertNotEquals \
   "`loglevel=debug shlog typo hello 2>/dev/null`" \
        "${MUSSEL_PROMPT} typo hello
hello"
}


#
# loglevel:info
#
test_shlog_loglevel_info_success() {
  local cmd="echo hello"
  assertEquals \
   "`loglevel=info shlog ${cmd}`" \
                         "hello"
}

test_shlog_loglevel_info_fail() {
  local cmd="echo hello"
  assertNotEquals \
   "`loglevel=info shlog ${cmd}`" \
       "${MUSSEL_PROMPT} ${cmd}\n${cmd}"
}

#
# loglevel:empty
#
test_shlog_loglevel_empty_success() {
  local cmd="echo hello"
  assertEquals \
   "`loglevel= shlog ${cmd}`" "hello"
}

test_shlog_loglevel_empty_fail() {
  local cmd="echo hello"
  assertNotEquals \
   "`loglevel= shlog ${cmd}`" \
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
test_shlog_dryrun_loglevel_default() {
  assertEquals "`dry_run=on           shlog date`" ""
  assertEquals "`dry_run=on loglevel= shlog date`" ""
}
test_shlog_dryrun_loglevel_debug_on() {
  assertEquals \
   "`dry_run=on loglevel=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_loglevel_debug_y() {
  assertEquals \
   "`dry_run=y loglevel=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_loglevel_debug_yes() {
  assertEquals \
   "`dry_run=yes loglevel=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_loglevel_debug_on() {
  assertEquals \
   "`dry_run=on loglevel=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}
test_shlog_dryrun_loglevel_debug_1() {
  assertEquals \
   "`dry_run=1 loglevel=debug shlog echo hello`" \
   "${MUSSEL_PROMPT} echo hello"
}

## shunit2

. ${shunit2_file}
