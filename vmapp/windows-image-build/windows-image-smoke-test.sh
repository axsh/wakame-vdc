#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

try()
{
    eval "$@" || reportfail "$@"
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail

WIN_VERSION="$1"
[ "$1" = 2008 ] || [ "$1" = 2012 ] || reportfail "first parameter must be 2008 or 2012"

# Assume Jenkins puts us in a suitable part of the disk hierarchy to create a build directory.
BDIR="dir${WIN_VERSION#20}"

if [ -d "$BDIR" ]; then
    (
	cd "$BDIR"
	setsid "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$WIN_VERSION" -cleanup
    )
    rm "$BDIR" -fr
fi

mkdir "$BDIR"  && cd "$BDIR" || reportfail "could not make build directory"

cleanup-code()
{
    echo "Doing post-test cleanup"
    setsid "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$WIN_VERSION" -cleanup
}

trap 'cleanup-code' EXIT


# Make sure resource files are in place

ensure-file-is-in-place()
{
    [ -f "$TARGETDIR/$1" ] && return 0
    for asource in $DLSOURCES; do
	case "$asource" in
	    /*)
		cp "$asource/$1" "$TARGETDIR/$1"
		;;
	    http://*)
		curl "$asource/$1" -o "$TARGETDIR/$1"
		;;
	    *)
		reportfail "unknown source: $asource"
		;;
	esac
	[ -f "$TARGETDIR/$1" ] && return 0
    done
    reportfail "Could not install $1"
}

localsource="$(echo /home/*/for-jenkins-windows-image-smoke-test)"
[ -d "$localsource" ] || localsource=""

TARGETDIR="$SCRIPT_DIR"
DLSOURCES="$localsource"

ensure-file-is-in-place SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_Japanese_w_SP1_MLF_X17-22600.ISO
ensure-file-is-in-place SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_Japanese_-3_MLF_X19-53644.ISO
ensure-file-is-in-place key2008
ensure-file-is-in-place key2012
ensure-file-is-in-place metadata.img.tar.gz

DLSOURCES="$localsource http://alt.fedoraproject.org/pub/alt/virtio-win/archives/virtio-win-0.1-74"
ensure-file-is-in-place virtio-win-0.1-74.iso

DLSOURCES="$localsource http://repo.zabbix.jp/zabbix/zabbix-1.8/windows"
ensure-file-is-in-place zabbix_agent-1.8.15-1.JP_installer.exe

cp "$SCRIPT_DIR/key${WIN_VERSION}" ./keyfile
tar xzvf "$SCRIPT_DIR/metadata.img.tar.gz"

# All the needed files should be in place. Start the build.

KILLPGOK=yes "$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$WIN_VERSION" 0-init
for i in $(seq 1 30); do
    echo "Iteration $i: "
    sudo whoami # keep sudo alive
    setsid "$SCRIPT_DIR/supernext.sh" -next
    cmd="$(< thisrun/nextstep)"
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

# for smoke tests, assume only run-*-000 exists
tar xzvOf ./run-$WIN_VERSION-000/after-gen0-sysprep.tar.gz   Windows/Setup/State/State.ini >State.ini

[[ "$(< State.ini)" == *IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE* ]] || reportfail "sysprep did not update State.ini file"
