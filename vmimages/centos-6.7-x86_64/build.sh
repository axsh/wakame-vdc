#!/bin/bash

# Because this script can be called independently,
# it must set up its bashsteps environment, e.g.
# reportfailed(), $skip_rest_if_already_done, etc.
source "$(dirname "$0")/bin/simple-defaults-for-bashsteps.source" || exit

# This step references data from the step that built (or will build)
# the base image.  If not otherwise set, assume it is relative to
# the DATADIR for this step.
oneup="${DATADIR%/*}"
twoup="${oneup%/*}"
: ${base_image_DATADIR:="$twoup/centos-6.7-x86_64-base/output"}
export base_image_DATADIR

(
    $starting_dependents "Build centos-6.7-x86_64 image"

    DATADIR="$base_image_DATADIR" "$CODEDIR/build-base-image-dir/build.sh" ; prev_cmd_failed

    for i in "$CODEDIR/steps-to-do"/*.sh; do
	"$i" ; prev_cmd_failed
    done

    export UUID=centos6
    "$CODEDIR/other-steps/steps-for-packaging.sh" \
	"$DATADIR/minimal-image.raw" \
	"$DATADIR/centos-6.7.x86_64.kvm.md.raw.tar.gz"

    $starting_checks
    true # this step just groups the above steps
    $skip_rest_if_already_done
)
