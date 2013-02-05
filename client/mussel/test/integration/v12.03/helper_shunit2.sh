# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions

## group variables


## group functions

function setup_vars_helper() {
  DCMGR_API_VERSION=$1
  DCMGR_HOST=${DCMGR_HOST:-10.0.2.15}
  DCMGR_PORT=${DCMGR_PORT:-9001}
  DCMGR_BASE_URI=${DCMGR_BASE_URI:-http://${DCMGR_HOST}:${DCMGR_PORT}/api/${DCMGR_API_VERSION}}
  account_id=a-shpoolxx
  DCMGR_RESPONSE_FORMAT=${DCMGR_RESPONSE_FORMAT:-yml}
}

## helpres

function base_index() {
  run_cmd  ${namespace} index
}

function base_index_ids() {
  base_index | grep -- '- :id:' | awk -F :id: '{print $2}'
}

## steps

function step_base_index() {
  base_index >/dev/null
  assertEquals $? 0
}

function step_base_show_ids() {
  local uuid
  while read uuid; do
    run_cmd ${namespace} show ${uuid} >/dev/null
    assertEquals $? 0
  done < <(base_index_ids)
}

##

setup_vars_helper 12.03
