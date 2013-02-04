# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions
. ${BASH_SOURCE[0]%/*}/../../helper_vars.sh

## group variables

echo setup_vars_helper 12.03
setup_vars_helper 12.03
echo ${DCMGR_BASE_URI}

## group functions
