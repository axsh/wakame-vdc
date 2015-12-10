#!/bin/bash

reportfailed()		      
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}

export CODEDIR="$(cd "$(dirname "$0")" && pwd -P)" || reportfailed CODEDIR

# check all directories first, before starting time-consuming builds
for i in "$@"; do
    [ -x "$CODEDIR/${i%/}/build.sh" ] || reportfailed "Build directory not found at $CODEDIR/${i%/}"
done

for i in "$@"; do
    echo "Starting execution of $CODEDIR/${i%/}/build.sh"
    "$CODEDIR/${i%/}/build.sh"
    echo
done
