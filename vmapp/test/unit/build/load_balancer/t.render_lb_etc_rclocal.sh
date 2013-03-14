#!/bin/bash
#
# requires:
#   bash
#

## include files

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/helper_shunit2.sh

## variables

## public functions

function test_render_lb_etc_rclocal() {
  render_lb_etc_rclocal >/dev/null
  assertEquals $? 0
}

function test_render_lb_etc_rclocal_content() {
  render_lb_etc_rclocal | grep -q -w ". /metadata/user-data"
  assertEquals $? 0

  # don't use "egrep" here.
  render_lb_etc_rclocal | grep -q -w 'route add -net ${AMQP_SERVER} netmask 255.255.255.255 dev eth1'
  assertEquals $? 0

  render_lb_etc_rclocal | grep -q -w "initctl start haproxy_updater"
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
