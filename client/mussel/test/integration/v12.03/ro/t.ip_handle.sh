#!/bin/bash
#
# requires:
#   bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh

## variables

declare namespace=$(namespace ${BASH_SOURCE[0]})

## functions

###

## shunit2

. ${shunit2_file}
