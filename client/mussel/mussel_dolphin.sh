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

. ${BASH_SOURCE[0]%/*}/functions_dolphin

# variables

## System part

LANG=C
LC_ALL=C

## MUSSEL part

load_musselrc

## DCMGR part

extract_args $*

DOLPHIN_HOST=${DOLPHIN_HOST:-localhost}
DOLPHIN_PORT=${DOLPHIN_PORT:-9004}
DOLPHIN_BASE_URI=${DOLPHIN_BASE_URI:-${base_uri:-http://${DOLPHIN_HOST}:${DOLPHIN_PORT}}}

# main

run_cmd ${MUSSEL_ARGS}
