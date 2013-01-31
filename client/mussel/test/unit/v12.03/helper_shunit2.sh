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
. ${abs_dirname}/../../../_v12.03

## group variables

api_version=${api_version:-12.03}
host=${host:-localhost}
port=${port:-9001}
base_uri=${base_uri:-http://${host}:${port}/api/${api_version}}
account_id=${account_id:-a-shpoolxx}
format=${format:-yml}

dry_run=yes

## group functions
