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
    setsid "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$BDIR/" -cleanup
}

trap 'echo "Doing post-test cleanup" ; cleanup-code >>"$SCRIPT_DIR/post-test-cleanup.out" 2>&1' EXIT

# Check for missing dependencies here so that time is not wasted
# running a test that will inevitably fail.
for i in s3cmd mkfs.vfat ntfslabel mount.ntfs
do
    which "$i" >/dev/null || reportfail "Must install package for $i"
done

# FYI:
# yum install s3cmd
# yum install dosfstools
# yum install ntfs-3g.x86_64 ntfsprogs.x86_64

WIN_VERSION="$1"
[ "$1" = 2008 ] || [ "$1" = 2012 ] || reportfail "first parameter must be 2008 or 2012"

source "$SCRIPT_DIR/windows-image-build.ini"

# Assume Jenkins puts us in a suitable part of the disk hierarchy to create a build directory.
BDIR="./builddirs/smoketest-$WIN_VERSION/"
evalcheck mkdir -p ./builddirs

# Make sure KVMs, processes, and build dir from previous jobs are deleted
if [ -d "$BDIR" ]; then
    echo "Removing existing build directory:"
    cleanup-code
    rm "$BDIR" -fr
fi

ensure-file-is-in-place()
{
    # Make sure the file "$1" is in "$TARGETDIR", and if not, try do
    # download it from each download path in the list "$DLSOURCES".
    [ -f "$TARGETDIR/$1" ] && return 0
    for asource in $DLSOURCES; do
	case "$asource" in
	    /*)
		cp -al "$asource/$1" "$TARGETDIR/$1" 2>/dev/null || \
		    cp "$asource/$1" "$TARGETDIR/$1" 2>/dev/null || \
		    echo "Attempt to copy $1 from local source failed" 1>&2
		;;
	    JenkinsENV)
		# try to grab an environment variable set by Jenkins, e.g.: JenkinsENV-key2008
		attempt="$(eval echo "\$${asource}_$1")"
		[ "$attempt" != "" ] && echo "$attempt" >"$TARGETDIR/$1"
		;;
	    http://* | https://*)
		curl --fail "$asource/$1" -o "$TARGETDIR/$1" || echo "Download attempt of $1 failed" 1>&2
		;;
	    s3://*)
		s3cmd get "$asource/$1" "$TARGETDIR/$1" || echo "s3cmd download attempt of $1 failed" 1>&2
		;;
	    *)
		reportfail "unknown source: $asource"
		;;
	esac
	[ -f "$TARGETDIR/$1" ] && return 0
    done
    reportfail "Could not install $1"
}

# Make sure resource files are in place.

localsource="$(echo /home/*/for-jenkins-windows-image-smoke-test)"
[ -d "$localsource" ] || localsource=""

TARGETDIR="$SCRIPT_DIR" # Currently, all these resource files go in the same directory as this script.

DLSOURCES="$localsource https://fedorapeople.org/groups/virt/virtio-win/deprecated-isos/archives/virtio-win-0.1-74"
ensure-file-is-in-place virtio-win-0.1-74.iso

DLSOURCES="$localsource http://repo.zabbix.jp/zabbix/zabbix-1.8/windows"
ensure-file-is-in-place zabbix_agent-1.8.15-1.JP_installer.exe

DLSOURCES="$localsource $S3URL JenkinsENV"  # S3URL is set in Jenkins
[ "$WIN_VERSION" = "2008" ] && \
    ensure-file-is-in-place key2008
[ "$WIN_VERSION" = "2012" ] && \
    ensure-file-is-in-place key2012

DLSOURCES="$localsource $S3URL"  # S3URL is set in Jenkins
isoname="$(eval echo \$ISO${WIN_VERSION})"
[ "$isoname" != "" ] || reportfail "Environment variable ISO${WIN_VERSION} must be set"
ensure-file-is-in-place "$isoname"

# All the needed files should now be in place. Start the build.

KILLPGOK=yes "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$BDIR" 0-init "$WIN_VERSION"

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
	tar xzvOf "./$BDIR/after-gen0-sysprep.tar.gz"   Windows/Setup/State/State.ini >State.ini

	[[ "$(< State.ini)" == *IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE* ]] || reportfail "sysprep did not update State.ini file"
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
