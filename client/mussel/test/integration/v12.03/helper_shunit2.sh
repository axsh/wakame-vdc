# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions
. ${BASH_SOURCE[0]%/*}/../../helper_retry.sh

## environment-specific configuration

[[ -f ${BASH_SOURCE[0]%/*}/musselrc ]] && { . ${BASH_SOURCE[0]%/*}/musselrc; } || :

## group variables

## group functions

function setup_vars() {
  DCMGR_API_VERSION=$1
  DCMGR_HOST=${DCMGR_HOST:-10.0.2.15}
  DCMGR_PORT=${DCMGR_PORT:-9001}
  DCMGR_BASE_URI=${DCMGR_BASE_URI:-http://${DCMGR_HOST}:${DCMGR_PORT}/api/${DCMGR_API_VERSION}}
  account_id=a-shpoolxx
  DCMGR_RESPONSE_FORMAT=${DCMGR_RESPONSE_FORMAT:-yml}
}

### helper

function hash_value() {
  local key=$1

  egrep -w ":${key}:" </dev/stdin | awk '{print $2}'
}

function document_pair?() {
  local namespace=$1 uuid=$2 key=$3 val=$4
  [[ "$(run_cmd ${namespace} show ${uuid} | hash_value ${key})" == "${val}" ]]
}

function namespace() {
  local namespace=$1
  namespace=${namespace##*/}
  namespace=${namespace##t.}
  namespace=${namespace%%.sh}
  echo ${namespace}
}

function base_index() {
  run_cmd  ${namespace} index
}

function base_index_uuids() {
  base_index | grep -- '- :id:' | awk -F :id: '{print $2}'
}

## steps

function step_base_index() {
  base_index >/dev/null
  assertEquals $? 0
}

function step_base_show_uuids() {
  local uuid
  while read uuid; do
    run_cmd ${namespace} show ${uuid} >/dev/null
    assertEquals $? 0
  done < <(base_index_uuids)
}

function step_base_show_invalid_uuid_syntax() {
  local uuid=invalid-uuid-syntax.$$
  run_cmd ${namespace} show ${uuid} 2>/dev/null
  assertNotEquals $? 0
}

##

setup_vars 12.03
