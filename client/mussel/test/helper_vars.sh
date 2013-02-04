# -*-Shell-script-*-
#
# requires:
#   bash
#

## group variables

function setup_vars_helper() {
  api_version=$1
  host=localhost
  port=9001
  base_uri=http://${host}:${port}/api/${api_version}
  account_id=a-shpoolxx
  format=yml
  http_header=X_VDC_ACCOUNT_UUID:${account_id}
}
