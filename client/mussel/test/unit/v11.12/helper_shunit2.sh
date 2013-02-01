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
. ${abs_dirname}/../../../_v11.12

## group variables

api_version=${api_version:-11.12}
host=${host:-localhost}
port=${port:-9001}
base_uri=${base_uri:-http://${host}:${port}/api/${api_version}}
account_id=${account_id:-a-shpoolxx}
format=${format:-yml}
declare http_header=X_VDC_ACCOUNT_UUID:${account_id}

dry_run=yes

## group functions
