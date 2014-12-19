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

trap 'echo "Doing post-test cleanup" ; cleanup-code' EXIT


WIN_VERSION="$1"
[ "$1" = 2008 ] || [ "$1" = 2012 ] || reportfail "first parameter must be 2008 or 2012"

# Assume Jenkins puts us in a suitable part of the disk hierarchy to create a build directory.
BDIR="./builddirs/smoketest-$WIN_VERSION/"
evalcheck mkdir -p ./builddirs

# Make sure KVMs, processes, and build dir from previous jobs are deleted
[ -d "$BDIR" ] && { cleanup-code ; rm "$BDIR" -fr ; }

ensure-file-is-in-place()
{
    # Make sure the file "$1" is in "$TARGETDIR", and if not, try do
    # download it from each download path in the list "$DLSOURCES".
    [ -f "$TARGETDIR/$1" ] && return 0
    for asource in $DLSOURCES; do
	case "$asource" in
	    /*)
		cp -al "$asource/$1" "$TARGETDIR/$1" || \
		    cp "$asource/$1" "$TARGETDIR/$1"
		;;
	    JenkinsENV)
		# try to grab an environment variable set by Jenkins, e.g.: JenkinsENV-key2008
		attempt="$(eval echo "\$${asource}_$1")"
		[ "$attempt" != "" ] && echo "$attempt" >"$TARGETDIR/$1"
		;;
	    http://*)
		curl "$asource/$1" -o "$TARGETDIR/$1"
		;;
	    s3://*)
		s3cmd get "$asource/$1" "$TARGETDIR/$1"
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

DLSOURCES="$localsource http://alt.fedoraproject.org/pub/alt/virtio-win/archives/virtio-win-0.1-74"
ensure-file-is-in-place virtio-win-0.1-74.iso

DLSOURCES="$localsource http://repo.zabbix.jp/zabbix/zabbix-1.8/windows"
ensure-file-is-in-place zabbix_agent-1.8.15-1.JP_installer.exe

DLSOURCES="$localsource $S3URL JenkinsENV"  # S3URL is set in Jenkins
[ "$WIN_VERSION" = "2008" ] && \
    ensure-file-is-in-place key2008
[ "$WIN_VERSION" = "2012" ] && \
    ensure-file-is-in-place key2012

DLSOURCES="$localsource $S3URL"  # S3URL is set in Jenkins
[ "$WIN_VERSION" = "2008" ] && \
    ensure-file-is-in-place SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_Japanese_w_SP1_MLF_X17-22600.ISO
[ "$WIN_VERSION" = "2012" ] && \
    ensure-file-is-in-place SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_Japanese_-3_MLF_X19-53644.ISO

ensure-file-is-in-place metadata.img.tar.gz



# All the needed files should now be in place. Start the build.

KILLPGOK=yes "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$BDIR" 0-init "$WIN_VERSION"

for i in $(seq 1 30); do
    echo "Iteration $i: "
    sudo whoami # keep sudo alive
    setsid "$SCRIPT_DIR/supernext.sh" -next "$BDIR"
    cmd="$(< "$BDIR/nextstep")"
    if [[ "$cmd" == *cannot-continue ]]; then
	echo "Build failed at step: $cmd"
	break
    fi
    if [ "$cmd" = "3-tar-the-image" ]; then
	echo "Finished."
	break
    fi
    ps -o pid,pgid,cmd
    sleep 60
done

# after-gen0-sysprep.tar.gz is the set of Windows log files after sysprep is run as
# the final step of installing Windows.  Extract just one file from this tar archive.
tar xzvOf "./$BDIR/after-gen0-sysprep.tar.gz"   Windows/Setup/State/State.ini >State.ini

[[ "$(< State.ini)" == *IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE* ]] || reportfail "sysprep did not update State.ini file"
