#!/bin/bash

# Because this script can be called independently,
# it must set up its bashsteps environment, e.g.
# reportfailed(), $skip_rest_if_already_done, etc.
source "$(dirname "$0")/bin/simple-defaults-for-bashsteps.source" || exit

source "$CODEDIR/build.conf"

# explicitly export configuration vars that will be needed in the substeps:
export CENTOSISO CENTOSMIRROR ISOMD5 MEMSIZE DISKSIZE

(
    $starting_dependents "Build centos-7.1.1503-x86_64-base image"

    for i in "$CODEDIR/steps-to-do"/*.sh; do
	"$i" ; prev_cmd_failed
    done

    $starting_checks
    true # this step just groups the above steps
    $skip_rest_if_already_done
)
