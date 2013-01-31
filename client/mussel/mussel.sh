#!/bin/bash
#
# mussel
#
LANG=C
LC_ALL=C

set -e

### read-only variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)

### include files

. ${abs_dirname}/functions

### prepare

extract_args $*

## main

api_version=${api_version:-12.03}
host=${host:-localhost}
port=${port:-9001}
base_uri=${base_uri:-http://${host}:${port}/api/${api_version}}
account_id=${account_id:-a-shpoolxx}
format=${format:-yml}

http_header=X_VDC_ACCOUNT_UUID:${account_id}

# include version
case "${api_version}" in
11.12) . ${abs_dirname}/_v11.12 ;;
12.03) . ${abs_dirname}/_v12.03 ;;
*)     . ${abs_dirname}/_v12.03 ;;
esac

run_cmd ${MUSSEL_ARGS}
