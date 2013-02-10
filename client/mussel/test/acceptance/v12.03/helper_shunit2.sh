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
  local key=$1 line

  egrep -w ":${key}:" </dev/stdin | awk '{print $2}'
}

function check_document_pair() {
  local namespace=$1 uuid=$2 key=$3 val=$4
  [[ "$(run_cmd ${namespace} show ${uuid} | hash_value ${key})" == "${val}" ]]
}

function retry_until() {
  local wait_sec=$1; shift;
  local blk="$@"

  local tries=0
  local start_at=$(date +%s)

  while :; do
    eval "${blk}" && {
      break
    } || {
      sleep 3
    }

    tries=$((${tries} + 1))
    if [[ "$(($(date +%s) - ${start_at}))" -gt "${wait_sec}" ]]; then
      echo "Retry Failure: Exceed ${wait_sec} sec: Retried ${tries} times" >&2
      return 1
    fi
  echo ... ${tries} $(date +%Y/%m/%d-%H:%M:%S)
  done
}

##

setup_vars 12.03
