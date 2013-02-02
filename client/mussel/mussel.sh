#!/bin/bash
#
# requires:
#  bash, pwd
#
# description:
#  wakame-vdc dcmgr(api) client
#
LANG=C
LC_ALL=C

set -e

### include files

. ${BASH_SOURCE[0]%/*}/functions

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
11.12) . ${BASH_SOURCE[0]%/*}/v11.12 ;;
12.03) . ${BASH_SOURCE[0]%/*}/v12.03 ;;
*)     . ${BASH_SOURCE[0]%/*}/v12.03 ;;
esac

run_cmd ${MUSSEL_ARGS}
