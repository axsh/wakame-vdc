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

declare api_version=11.12
declare host=localhost
declare port=9001
declare base_uri=http://${host}:${port}/api/${api_version}
declare account_id=a-shpoolxx
declare format=yml
declare http_header=X_VDC_ACCOUNT_UUID:${account_id}

declare dry_run=yes

## group functions
