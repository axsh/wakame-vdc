#!/bin/bash
#
# requires:
#  bash
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

## variables

DCMGR_API_VERSION=${DCMGR_API_VERSION:-${api_version:-12.03}}
DCMGR_HOST=${DCMGR_HOST:-${host:-localhost}}
DCMGR_PORT=${DCMGR_PORT:-${port:-9001}}
DCMGR_BASE_URI=${DCMGR_BASE_URI:-${base_uri:-http://${DCMGR_HOST}:${DCMGR_PORT}/api/${DCMGR_API_VERSION}}}

format=${format:-yml}

# main

run_cmd ${MUSSEL_ARGS}
