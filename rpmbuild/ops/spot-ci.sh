#!/bin/bash

set -e
set -x

# min
interval=${1:-1}

while date; do
  git pull

  time sudo ./spot-build.sh
  time ./spot-sync.sh

  date
  echo sleeping ${interval} min.
  sleep $((60 * ${interval}))
done
