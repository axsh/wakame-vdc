# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly shunit2_file=${BASH_SOURCE[0]%/*}/../../shunit2

## include files

. ${BASH_SOURCE[0]%/*}/../../../functions
. ${BASH_SOURCE[0]%/*}/../../helpers/vars.sh

## group variables

setup_vars 11.12

declare MUSSEL_DRY_RUN=yes

## group functions
