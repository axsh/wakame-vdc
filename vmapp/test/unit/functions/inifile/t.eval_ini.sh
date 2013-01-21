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

function test_eval_ini() {
  eval_ini ${inifile} ${section_name}

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

function test_eval_ini_prefix() {
  eval_ini ${inifile} ${section_name} config

  assertEquals "${config_log_error}" /var/log/mysqld.log
  assertEquals "${config_pid_file}"  /var/run/mysqld/mysqld.pid
}

## shunit2

. ${shunit2_file}
