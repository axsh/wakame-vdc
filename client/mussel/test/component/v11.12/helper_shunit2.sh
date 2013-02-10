# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions
. ${BASH_SOURCE[0]%/*}/../../helper_vars.sh

## group variables

setup_vars 11.12

## group functions

function curl_opts() { :; }
function curl() { echo curl $*; }

##

function cli_wrapper() {
  extract_args $*
  run_cmd ${MUSSEL_ARGS}
}
