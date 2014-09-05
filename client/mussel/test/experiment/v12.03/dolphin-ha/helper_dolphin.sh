#!/bin/bash
#
# requires:
#   bash
#

## include files
. ${BASH_SOURCE[0]%/*}/../../../../functions_dolphin
. ${BASH_SOURCE[0]%/*}/../../../helpers/dolphin.sh

## variables

## functions
function setup_dolphin_vars() {
  DOLPHIN_HOST=${DOLPHIN_HOST:-localhost}
  DOLPHIN_PORT=${DOLPHIN_PORT:-9004}
  DOLPHIN_BASE_URI=${DOLPHIN_BASE_URI:-${base_uri:-http://${DOLPHIN_HOST}:${DOLPHIN_PORT}}}
}

### instance

### shunit2 setup
setup_dolphin_vars

