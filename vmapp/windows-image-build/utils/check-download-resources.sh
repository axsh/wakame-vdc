#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail

WIN_VERSION="$1"
[ "$1" = 2008 ] || [ "$1" = 2012 ] || reportfail "first parameter must be 2008 or 2012"

source "$SCRIPT_DIR/../windows-image-build.ini"

# Check for missing install dependencies here so that time is not
# wasted running a test that will inevitably fail.
deps="mkfs.vfat ntfslabel mount.ntfs"
[ "$S3URL" != "" ] && deps="s3cmd $deps"
for i in $deps
do
    which "$i" >/dev/null || reportfail "Must install package for $i"
done

# Hints:
# yum install s3cmd
# yum install dosfstools
# yum install ntfs-3g.x86_64 ntfsprogs.x86_64

check-resource-file()
{
    [ -f "$TARGETDIR/$1" ] && {
	echo "Installed: $1"
    }
}

ensure-file-is-in-place()
{
    # Make sure the file "$1" is in "$TARGETDIR", and if not, try do
    # download it from each download path in the list "$DLSOURCES".
    check-resource-file "$1" && return 0
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
	check-resource-file "$1" && return 0
    done
    reportfail "Could not install $1"
}

# Make sure resource files are in place.

localsource="$(echo /home/*/for-jenkins-windows-image-smoke-test)"
[ -d "$localsource" ] || localsource=""

TARGETDIR="$SCRIPT_DIR/../resources"

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

echo "All required resources were found."
