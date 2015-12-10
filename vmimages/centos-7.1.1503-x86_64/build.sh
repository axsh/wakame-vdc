#!/bin/bash

# Because this script can be called independently,
# it must set up its bashsteps environment, e.g.
# reportfailed(), $skip_rest_if_already_done, etc.
source "$(dirname "$0")/bin/simple-defaults-for-bashsteps.source" || exit

(
    $starting_dependents "Build centos-7.1.1503-x86_64 image"

    "$CODEDIR/build-base-image-dir/build.sh" ; prev_cmd_failed

    for i in "$CODEDIR/steps-to-do"/*.sh; do
	"$i" ; prev_cmd_failed
    done

    export UUID=centos7
    "$CODEDIR/other-steps/steps-for-packaging.sh" \
	"$DATADIR/minimal-image.raw" \
	"$DATADIR/centos-7.x86_64.kvm.md.raw.tar.gz"

    $starting_checks
    true # this step just groups the above steps
    $skip_rest_if_already_done
)
