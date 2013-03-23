#!/bin/bash
#
# requires:
#  bash
#
# description:
#  wakame-vdc dcmgr(api) client
#
set -e

# include files

. ${BASH_SOURCE[0]%/*}/functions

# variables

## System part

LANG=C
LC_ALL=C

## MUSSEL part

load_musselrc

## DCMGR part

extract_args $*

DCMGR_API_VERSION=${DCMGR_API_VERSION:-${api_version:-12.03}}
DCMGR_HOST=${DCMGR_HOST:-localhost}
DCMGR_PORT=${DCMGR_PORT:-9001}
DCMGR_BASE_URI=${DCMGR_BASE_URI:-${base_uri:-http://${DCMGR_HOST}:${DCMGR_PORT}/api/${DCMGR_API_VERSION}}}
DCMGR_RESPONSE_FORMAT=${DCMGR_RESPONSE_FORMAT:-${DCMGR_RESPONSE_FORMAT:-yml}}

# main

run_cmd ${MUSSEL_ARGS}
