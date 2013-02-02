#!/bin/bash
#
# requires:
#  bash
#  date, nc
#

addr=${addr:-127.0.0.1}
port=${port:-9001}

trap "exit;" INT

while echo === ${addr}:${port} ===; do
  date | nc ${addr} -l ${port}
done
