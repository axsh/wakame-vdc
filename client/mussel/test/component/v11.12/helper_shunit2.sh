# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
readonly shunit2_file=${abs_dirname}/../../shunit2

## include files

. ${abs_dirname}/../../../functions
. ${abs_dirname}/../../../v11.12

## group variables

declare api_version=11.12
declare host=localhost
declare port=9001
declare base_uri=http://${host}:${port}/api/${api_version}
declare account_id=a-shpoolxx
declare format=yml
declare http_header=X_VDC_ACCOUNT_UUID:${account_id}

## group functions

function curl_opts() { :; }
function curl() { echo curl $*; }

##

function cli_wrapper() {
  extract_args $*
  run_cmd ${MUSSEL_ARGS}
}
