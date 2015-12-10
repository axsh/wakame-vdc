#!/bin/bash

######################################################################
## Directory Paths
######################################################################

export CODEDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfailed
export DATADIR="/proc/self"  # i.e. not set yet

# put the current directory someplace unwritable to force use
# of the above variables
cd -P /proc/self

######################################################################
## Build Steps
######################################################################

# set reportfailed, $skip_rest_if_already_done, etc.
source "$CODEDIR/bin/simple-defaults-for-bashsteps.source"

# check all directories first, before starting time-consuming builds
for i in "$@"; do
    [ -x "$CODEDIR/${i%/}/build.sh" ] || reportfailed "Build directory not found at $CODEDIR/${i%/}"
done

for i in "$@"; do
    echo "Starting execution of $CODEDIR/${i%/}/build.sh"
    "$CODEDIR/${i%/}/build.sh"
    echo
done
