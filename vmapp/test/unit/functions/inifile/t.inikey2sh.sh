#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

declare kv_file=${abs_dirname}/kv_file.$$
declare section_name=mysqld_safe

## functions

function setUp() {
  cat <<-EOS > ${kv_file}
	log-error="/var/log/mysqld.log"
	pid-file="/var/run/mysqld/mysqld.pid"
	EOS

  log_error=
  pid_file=
}

function tearDown() {
  rm -f ${kv_file}
}

function test_ini2shvar_filter() {
  eval "$(cat ${kv_file} | inikey2sh)"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

function test_ini2shvar_file() {
  eval "$(inikey2sh ${kv_file})"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}

function test_ini2shvar_redirect() {
  eval "$(inikey2sh < ${kv_file})"

  assertEquals "${log_error}" /var/log/mysqld.log
  assertEquals "${pid_file}"  /var/run/mysqld/mysqld.pid
}


## shunit2

. ${shunit2_file}
