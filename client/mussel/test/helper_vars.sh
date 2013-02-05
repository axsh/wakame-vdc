# -*-Shell-script-*-
#
# requires:
#   bash
#

## group variables

function setup_vars_helper() {
  DCMGR_API_VERSION=$1
  DCMGR_HOST=localhost
  DCMGR_PORT=9001
  DCMGR_BASE_URI=http://${DCMGR_HOST}:${DCMGR_PORT}/api/${DCMGR_API_VERSION}
  account_id=a-shpoolxx
  format=yml
}
