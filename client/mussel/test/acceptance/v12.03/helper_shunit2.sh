# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions
. ${BASH_SOURCE[0]%/*}/../../helpers/retry.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/document.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/ssh.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/instance.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/load_balancer.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/ssl.sh
. ${BASH_SOURCE[0]%/*}/../../helpers/interactive.sh

## environment-specific configuration

[[ -f ${BASH_SOURCE[0]%/*}/musselrc ]] && { . ${BASH_SOURCE[0]%/*}/musselrc; } || :
load_musselrc

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

##

setup_vars 12.03
