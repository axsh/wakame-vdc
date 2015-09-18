#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

evalcheck()
{
    eval "$@" || reportfail "$@,rc=$?"
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail

cleanup-code()
{
    setsid "$SCRIPT_DIR/../build-w-answerfile-floppy.sh" "$BDIR/" -cleanup
}

trap 'echo "Doing post-test cleanup" ; cleanup-code >>"$SCRIPT_DIR/post-test-cleanup.out" 2>&1' EXIT

WIN_VERSION="$1"
[ "$1" = 2008 ] || [ "$1" = 2012 ] || reportfail "first parameter must be 2008 or 2012"

source "$SCRIPT_DIR/../windows-image-build.ini"

# Assume Jenkins puts us in a suitable part of the disk hierarchy to create a build directory.
BDIR="$SCRIPT_DIR/../builddirs/smoketest-$WIN_VERSION/"
evalcheck mkdir -p ./builddirs

# Make sure KVMs, processes, and build dir from previous jobs are deleted
if [ -d "$BDIR" ]; then
    echo "Removing existing build directory:"
    cleanup-code
    rm "$BDIR" -fr
fi

"$SCRIPT_DIR/check-download-resources.sh" "$WIN_VERSION" || exit
# All the needed files should now be in place. Start the build.

KILLPGOK=yes "$SCRIPT_DIR/../build-w-answerfile-floppy.sh" "$BDIR" 0-init "$WIN_VERSION"

SLEEPTIME=60
MAXITERATIONS=30

for i in $(seq 1 $MAXITERATIONS); do
    echo
    echo "Iteration $i for windows-image-smoke-test.show-image.sh:"
    sudo whoami 1>/dev/null # keep sudo alive
    setsid "$SCRIPT_DIR/supernext.sh" -next "$BDIR"
    cmd="$(< "$BDIR/nextstep")"
    if [ "$cmd" = "3-tar-the-image" ]; then
	# after-gen0-sysprep.tar.gz is the set of Windows log files after sysprep is run as
	# the final step of installing Windows.  Extract just one file from this tar archive.
	tar xzvOf "$BDIR/after-gen0-sysprep.tar.gz"   Windows/Setup/State/State.ini >"$BDIR/State.ini"

	[[ "$(< "$BDIR/State.ini")" == *IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE* ]] || reportfail "sysprep did not update State.ini file"
	echo "Continuing on to package image..."
    fi
    if [ "$cmd" = "1001-gen0-first-boot" ]; then
	echo "Finished."
	break
    fi
    echo
    echo "(Sleeping for $SLEEPTIME seconds)"
    sleep $SLEEPTIME
done
