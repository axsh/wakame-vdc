#!/bin/bash
#
# mussel
#
LANG=C
LC_ALL=C

set -e

abs_path=$(cd $(dirname $0) && pwd)
. ${abs_path}/functions

#
api_version=${api_version:-12.03}
host=${host:-localhost}
port=${port:-9001}
base_uri=${base_uri:-http://${host}:${port}/api/${api_version}}
account_id=${account_id:-a-shpoolxx}
format=${format:-yml}

http_header=X_VDC_ACCOUNT_UUID:${account_id}
# include version
case "${api_version}" in
11.12) . ${abs_path}/_v11.12 ;;
12.03) . ${abs_path}/_v12.03 ;;
*)     . ${abs_path}/_v12.03 ;;
esac

run_cmd ${args}
