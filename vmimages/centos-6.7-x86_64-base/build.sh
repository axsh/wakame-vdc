#!/bin/bash

######################################################################
## Directory Paths
######################################################################

export CODEDIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfailed
export DATADIR="$CODEDIR/output"

# put the current directory someplace unwritable to force use
# of the above variables
cd -P /proc/self

######################################################################
## Build Steps
######################################################################

# set reportfailed, $skip_rest_if_already_done, etc.
source "$CODEDIR/bin/simple-defaults-for-bashsteps.source"

source "$CODEDIR/build.conf"

(
    $starting_dependents "Build centos-6.7-x86_64-base image"

    for i in "$CODEDIR/steps-to-do"/*.sh; do
	"$i" ; prev_cmd_failed
    done

    $starting_checks
    true # this step just groups the above steps
    $skip_rest_if_already_done
)
