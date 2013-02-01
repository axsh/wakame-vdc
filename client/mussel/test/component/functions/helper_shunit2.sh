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

## group variables

declare api_version=12.03
declare host=localhost
declare port=9001
declare base_uri=http://${host}:${port}/api/${api_version}
declare account_id=a-shpoolxx
declare format=yml
declare http_header=X_VDC_ACCOUNT_UUID:${account_id}

## group functions

function curl_opts() { :; }
function curl() { echo curl $*; }
