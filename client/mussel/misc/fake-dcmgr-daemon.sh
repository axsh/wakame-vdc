#!/bin/bash
#
# requires:
#  bash
#  date, nc
#

DCMGR_HOST=${DCMGR_HOST:-${host:-localhost}}
DCMGR_PORT=${DCMGR_PORT:-${port:-9001}}

trap "exit;" INT

while echo === ${DCMGR_HOST}:${DCMGR_PORT} ===; do
  date | nc ${DCMGR_HOST} -l ${DCMGR_PORT}
done
