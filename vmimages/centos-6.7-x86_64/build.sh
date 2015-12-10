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
## Inline Steps
######################################################################

# set reportfailed, $skip_rest_if_already_done, etc.
source "$CODEDIR/bin/simple-defaults-for-bashsteps.source"

(
    $starting_dependents "Build centos-6.7-x86_64 image"

    "$CODEDIR/build-base-image-dir/build.sh" ; prev_cmd_failed

    for i in "$CODEDIR/steps-to-do"/*.sh; do
	"$i" ; prev_cmd_failed
    done

    export UUID=centos6
    "$CODEDIR/set-of-steps/steps-for-packaging.sh" \
	"$DATADIR/minimal-image.raw" \
	"$DATADIR/centos-6.7.x86_64.kvm.md.raw.tar.gz"

    $starting_checks
    true # this step just groups the above steps
    $skip_rest_if_already_done
)
