#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## functions

function test_ini_section_no_opts() {
  mycnf | ini_section
  assertNotEquals 0 $?
}

function test_ini_section_known_section() {
  local section_name=mysqld_safe

  assertNotEquals "$(mycnf | ini_section ${section_name} | wc -l)" 0
}

function test_ini_section_unknown_section() {
  local section_name=asdf

  assertEquals "$(mycnf | ini_section ${section_name} | wc -l)" 0
}


## shunit2

. ${shunit2_file}
