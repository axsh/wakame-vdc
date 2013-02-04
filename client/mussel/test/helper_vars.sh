# -*-Shell-script-*-
#
# requires:
#   bash
#

## group variables

function setup_vars_helper() {
  DCMGR_API_VERSION=$1
  DCMGR_HOST=localhost
  port=9001
  base_uri=http://${DCMGR_HOST}:${port}/api/${DCMGR_API_VERSION}
  account_id=a-shpoolxx
  format=yml
  http_header=X_VDC_ACCOUNT_UUID:${account_id}
}
