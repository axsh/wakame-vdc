#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare section_name=mysqld_safe

## functions

function setUp() {
  mycnf > ${inifile}

  log_error=
  pid_file=
}

function tearDown() {
  rm -f ${inifile}
}

function test_parse_ini_file() {
  eval "$(parse_ini ${section_name} ${inifile} )"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

function test_parse_ini_filter() {
  eval "$(cat ${inifile} | parse_ini ${section_name})"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

function test_parse_ini_redirect() {
  eval "$(parse_ini ${section_name} < ${inifile})"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

## shunit2

. ${shunit2_file}
