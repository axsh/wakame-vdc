#!/bin/bash

# What this code does is relatively simple, but worth encapsulating
# because it is code that must run as root that can be a little
# confusing and a little dangerous.

# In short, the code mounts a file system from a partition inside an
# image file. This only requires a few steps: (1) find the location
# of the partition inside the file, (2) attach that part of the file
# to a loop block device, (3) mount that loop device to a mount point.

# Other solutions already exist that encapsulate steps (1) and (2),
# such as: kpart, qemu-nbd, and even recent versions of the Linux
# kernel itself using just losetup(!).  A mount command with a '-o
# loop' option encapsulates steps (2) and (3).  (Plus there already
# have been at least two hacks done locally.)  Unfortunately, all have
# disadvantages, or we have had unexplained reliability problems with
# them, and none encapsulates all three steps.  (TODO: expand this
# paragraph somewhere to explain the disadvantages)

# One thing that perhaps makes such code confusing is that later the
# mount must be undone, and this requires root, and it is possible
# that the code will undo a mount of something else running on the OS
# (or its nested containers).  So it is necessary to keep enough
# information when mounting to safely unmount and detach everything
# later.

# An important insight that made the code below simpler is that the
# losetup command has an "--associated" option that makes it easy to
# find the loop device mapping a particular partition.  Therefore, if
# the calling code remembers the path of the image file and the
# partition number, it is easy find the loop device.  From the loop
# device, it is easy to find mount points from /proc/mounts.

# To keep things portable, the code below relies only on these commands
# and options:
#
#     sfdisk -d "$imageFile1"
#     parted "$imageFile" unit B print
#     parted -s -m "$imageFile" unit B print
#     losetup --associated "$imageFile"
#     losetup --associated "$imageFile" --offset "$start"
#     losetup --find --show "$imageFile" --offset "$start" --sizelimit "$size"
#     losetup -d "$loopDevice"
#     mount "$loopDev" "$mountPoint"
#     umount "$loopDev"

# (A mistake made on the earlier version of the code was to save the
#  loop device information and use it later.  The problem this raised
#  was that it is difficult to verify that events outside the
#  process's control have not made the information invalid.  The the
#  first attempt to verify only worked with some versions of losetup.
#  It turned out to be easier to regenerate the loop device
#  information than to verify that saved information is correct! But
#  that is only true if regenerating is scripted...as it is below.)

mount-partition-usage()
{
    cat <<EOF
This file is meant to be sourced, and then the functions below
called directly.  When sourced, the keyword "load" must
be the first parameter, e.g.: "source ./mount-partition.sh load"

MOUNT-PARTITION
===============

mount-partition disk-image.raw
  # lists the partitions in the image

mount-partition /path/to/disk-image.raw N
  # mount partition, but do not mount file system

mount-partition /path/to/disk-image.raw N /path/to/mount-point
  # mounts partition number N at mount-point
  # -o 'mount,options,such,as,ro' can be appended to set mount options


UMOUNT-PARTITION
===============

umount-partition /path/to/disk-image.raw
  # detach any loop devices for this image after removing any mounts

umount-partition /path/to/disk-image.raw N
  # detach any loop devices for this partition after removing any mounts

umount-partition /path/to/disk-image.raw N /path/to/mount-point
  # same as above, but verify that it is mounted to mount-point first as a sanity check
  # (so multiple processes can safely mount the partition read-only)

umount-partition /path/to/mount-point
  # unmounts loop device from mount-point and detaches the image file

Since the above are bash functions, sudo will not work.  Therefore,
--sudo can be appended to any of the above to have the functions
insert a call to sudo for commands that need it.

When easier, the file can also be used as a script with "mount" or
"umount" as the first parameter.  One of the above functions is then
called with the remaining arguments.  In this case, normal sudo will
work.

EOF
}

get-loop-list-from-imagefile()
{
    imageFile="$1"
    offset="$2"  # optional parameter
    [ "$offset" != "" ] && offset="--offset $offset"
    $USESUDO losetup --associated "$imageFile" $offset | \
	while read ln; do
	    # assume each line starts with device path followed by a colon
	    loopdev="${ln%%:*}"
	    if [[ "$loopdev" == /dev/loop* ]]; then
		echo "$loopdev"
	    else
		echo "Unexpected output from losetup: $ln" 1>&2
		# don't confuse calling code with unexpected output, so no echo here
	    fi
	done
}

convert-excapes()
{
    # Converts octal escapes like those used in /proc/mounts paths.
    # Using bash's built-in $'string' construct, but first must
    # change quotes to octal to not close the construct accidentally.
    step1="${1//\'/\047}"
    step2="$'${step1}'"
    eval echo "$step2"
}

get-mountpoint-list-from-device-list()
{
    for device in "$@"; do
	# For example:
	# /dev/loop0 /tmp/test/m vfat rw,relatime,fmask=0022,dmask=0022,codepage=850,iocharset=utf8,shortname=mixed,errors=remount-ro 0 0
	while read adev apath rest; do
	    [ "$device" = "$adev" ] && echo "$adev $apath"
	done </proc/mounts
    done
}

do-list-partitions()
{
    imageFile="$1"
    [ -f "$imageFile" ] || {
	echo "First parameter must an existing image file. Exiting." 1>&2
	return 1
    }
    thecmd=( parted "$imageFile" unit B print )
    echo "Listing partitions with the command: \"${thecmd[*]}\""
    "${thecmd[@]}"
}

partition-info-from-parted()
{
    imageFile="$1"
    partionNumber="$2"
    parted -s -m "$1" unit B print | (
	# example output:
	# BYT;
	# /media/sdc1/images/win-2012.raw:32212254720B:file:512:512:msdos::;
	# 1:1048576B:368050175B:367001600B:ntfs::boot;
	# 2:368050176B:32211206143B:31843155968B:ntfs::;
	pattern="$partionNumber:*"
	while read ln; do
	    if [[ "$ln" == $pattern ]]; then
		ln="${ln//B/}" # get rid of the B suffixes
		IFS=: read n start end size fs rest <<<"$ln"
		echo "$start $size"
		exit 0 # (partition not found) exit from subshell
	    fi
	done
	echo "Partition number $partionNumber not found in output from parted" 1>&2
	exit 1 # (partition not found) exit from subshell
    )
}

partition-info-from-sfdisk()
{
    imageFile="$1"
    partionNumber="$2"
    sfdisk -d "$1" | (
	# example output:
	# label: dos
	# label-id: 0x0188d0f2
	# device: builddirs/friday1/win-2012.raw
	# unit: sectors
	# ./win-2012.raw1 : start=        2048, size=      716800, type=7, bootable
	# ./win-2012.raw2 : start=      718848, size=    62193664, type=7
	n=0
	while read ln; do
	    if [[ "$ln" == *start=*size=* ]]; then
		n=$(( n + 1 ))
		if [ "$n" -eq "$partionNumber" ]; then
		    ln="${ln##*:}"
		    IFS=', ' read startLabel start sizeLabel size rest <<<"$ln"
		    echo "$(( 512 * start )) $(( 512 * size ))"
		    exit 0 # (partition not found) exit from subshell
		fi
	    fi
	done
	echo "Partition number $partionNumber not found in output from sfdisk" 1>&2
	exit 1 # (partition not found) exit from subshell
    )
}

get-partition-info()
{
    # The offset information is critical and getting it wrong could
    # cause data loss.  Reading the documentation of commands like
    # sfdisk, parted, fdisk, etc is a little scary.  For example,
    # sfdisk "not designed for large partitions".  How large?  Does
    # not say.  Therefore, in an effort to make the code safer, both
    # sfdisk and parted are used and their results confirmed to match
    # before proceeding.
    imageFile="$1"
    partionNumber="$2"
    [ -f "$imageFile" ] || {
	echo "First parameter must an existing image file. Exiting." 1>&2
	return 1
    }
    [ "$partionNumber" != "" ] && [ "${partionNumber//[0-9]/}" = "" ] || {
	echo "Second parameter must a number. Exiting." 1>&2
	return 1
    }
    pinfo="$(partition-info-from-parted "$imageFile" "$partionNumber")" || return
    sinfo="$(partition-info-from-sfdisk "$imageFile" "$partionNumber")" || return
    [ "$pinfo" = "$sinfo" ] || {
	echo "Information parsed from sfdisk and parted do not agree. Exiting." 1>&2
	return 1
    }
    echo "$pinfo"
}

do-attach-partition()
{
    imageFile="$1"
    partionNumber="$2"
    pinfo="$(get-partition-info "$imageFile" "$partionNumber")" || return
    read start size <<<"$pinfo"
    precheck="$($USESUDO losetup --associated "$imageFile" --offset "$start")"
    if [ "$precheck" != "" ]; then
	loopdev="${precheck%%:*}"
	echo "Reusing exiting mount:" 1>&2
	echo "$precheck" 1>&2
    else
	loopdev="$($USESUDO losetup --find --show "$imageFile" --offset "$start" --sizelimit "$size")"
	rc="$?"
	[ "$rc" = 0 ] && [[ "$loopdev" == /dev/loop* ]] || {
	    echo "Error occured with losetup command (rc=$rc) or output was unexpected ($loopdev)." 1>&2
	    return 1
	}
    fi
    echo "$loopdev"
}

do-mount-partition()
{
    imageFile="$1"
    partionNumber="$2"
    mountPoint="$3"
    [ -d "$mountPoint" ] && (
	cd "$mountPoint"
	shopt -s nullglob
	[ "$(echo *)" = "" ]
    ) || {
	echo "Third parameter must be an existing directory that is empty. Exiting." 1>&2
	return 1
    }
    loopDev="$(do-attach-partition "$imageFile" "$partionNumber")" || return
    # Not sure what to do here, so now it is possible to do "export MultipleMounts=OK" and
    # mount the same loop twice,  which is OK with Linux.
    if [ "$MultipleMounts" = "" ]; then
	mounts="$(grep ^"$loopDev " </proc/mounts)" # space in pattern so loop1 does not match loop10
	[ "$mounts" = "" ] || {
	    echo "Exiting without mounting, because the loop device $loopDev is already mounted:" 1>&2
	    echo "(Add -multi as a parameter to allow multiple mounts)" 1>&2
	    echo "$mounts"
	    return 1
	}
    fi
    $USESUDO mount "$loopDev" "$mountPoint" $MOUNTOPTIONS || {
	echo "The mount command failed ($?). $loopDev is still attached to the image file." 1>&2
	return 1
    }
}

do-unmount-image()
{
    imageFile="$1"
    offset="$2"  # optional parameter
    looplist="$(get-loop-list-from-imagefile "$imageFile" "$offset")"
    mountlist="$(get-mountpoint-list-from-device-list $looplist)"
    if [ "$looplist$mountlist" = "" ]; then
	echo "Nothing to do." 1>&2
	return 1
    fi
    if [ "$mountlist" != "" ]; then
	while read aDev aMountPath; do
	    decoded="$(convert-excapes "$aMountPath")"
	    echo "Unmounting: $decoded"
	    $USESUDO umount "$decoded"
	done <<<"$mountlist"
	mountlist2="$(get-mountpoint-list-from-device-list $looplist)"
	if [ "$mountlist2" != "" ]; then
	    echo "Stopping because following mount points remain:" 1>&2
	    echo "$mountlist2" 1>&2
	    echo "No loop devices were detached." 1>&2
	    return 1
	fi
    fi
    if [ "$looplist" != "" ]; then
	for i in $looplist; do
	    echo "Detaching: $i"
	    $USESUDO losetup -d "$i"
	done
	looplist2="$(get-loop-list-from-imagefile "$imageFile" "$offset")"
	if [ "$looplist2" != "" ]; then
	    echo "The following loop devices could not be detached:" 1>&2
	    echo "$looplist2" 1>&2
	    return 1
	fi
    fi
    return 0
}

do-unmount-partition()
{
    imageFile="$1"
    partionNumber="$2"
    pinfo="$(get-partition-info "$imageFile" "$partionNumber")" || return
    read start size <<<"$pinfo"
    do-unmount-image "$imageFile" "$start"
}

do-unmount-partition-verify()
{
    imageFile="$1"
    partionNumber="$2"
    verifyMount="$3"
    vabsolute="$(cd "$verifyMount" && pwd -P)" # deal with relative paths, links, etc

    pinfo="$(get-partition-info "$imageFile" "$partionNumber")" || return
    read start size <<<"$pinfo"
    looplist="$(get-loop-list-from-imagefile "$imageFile" "$start")"
    mountlist="$(get-mountpoint-list-from-device-list $looplist)"
    if [ "$mountlist" = "" ]; then
	echo "Nothing to do." 1>&2
	if [ "$looplist" != "" ]; then
	    echo "Note the following attached loop devices remain:" 1>&2
	    echo "$looplist"
	fi
	return 1
    fi
    toDetach=""
    while read aDev aMountPath; do
	decoded="$(convert-excapes "$aMountPath")"
	dabsolute="$(cd "$decoded" && pwd -P)"
	if [ "$vabsolute" != "$dabsolute" ]; then
	    echo "Skipping unmount of $aDev $decoded" 1>&2
	    continue
	fi
	toDetach="$toDetach $aDev"
	echo "Unmounting: $decoded"
	$USESUDO umount "$decoded"
    done <<<"$mountlist"
    for i in $toDetach; do
	echo "Detaching: $i"
	$USESUDO losetup -d "$i"
    done
    report-missed-detaches || return
    return 0
}

report-missed-detaches()
{
    missed="$(
	all="$($USESUDO losetup -a)"
	for i in "$@"; do
	    grep "^$i:" <<<"$all"
	done )"
    if [ "$missed" != "" ]; then
	echo "Detaching failed for the following:" 1>&2
	echo "$missed" 1>&2
	return 1
    fi
}

get-device-from-mount-point()
{
    mountPoint="$1"
    mabsolute="$(cd "$mountPoint" && pwd -P)" || return # deal with relative paths, links, etc
    while read adev apath rest; do
	[[ "$adev" == /dev/loop* ]] || continue
	decoded="$(convert-excapes "$apath")"
	dabsolute="$(cd "$decoded" 2>/dev/null && pwd -P)"
	if [ "$mabsolute" = "$dabsolute" ]; then
	    echo "$adev"
	    break
	fi
    done </proc/mounts
}

do-unmount-mountpoint()
{
    mountPoint="$1"
    loopdev="$(get-device-from-mount-point "$mountPoint")"
    if [ "$loopdev" = "" ]; then
	echo "Not mounted to loop device. Nothing to do." 1>&2
	return 1
    fi

    echo "Unmounting: $mountPoint"
    $USESUDO umount "$mountPoint"
    check="$(get-device-from-mount-point "$mountPoint")"
    if [ "$check" != "" ]; then
	echo "Unmount failed" 1>&2
	return 1
    fi
    echo "Detaching: $loopdev"
    $USESUDO losetup -d "$loopdev"
    report-missed-detaches "$loopdev"
}

parse-mpparams()
{
    mpparams=( )
    for p in "$@"; do
	case "$p" in
	    -o) MOUNTOPTIONS="-o" ;;
	    -sudo | --sudo) USESUDO=sudo ;;
	    -multi | --multi) MultipleMounts=OK ;;
	    *)
		if [ "$MOUNTOPTIONS" = "-o" ]; then
		    MOUNTOPTIONS="-o $p"
		else
		    mpparams=( "${mpparams[@]}" "$p" )
		fi
		;;
	esac
    done
}

mount-partition()
{
    ( # subshell to keep options set by parameters local
	parse-mpparams "$@"
	case "${#mpparams[@]}" in
	    1)  do-list-partitions "${mpparams[@]}" ;;
	    2)  do-attach-partition "${mpparams[@]}" ;;
	    3)  do-mount-partition "${mpparams[@]}" ;;
	    *)  mount-partition-usage ;;
	esac
    )
}

umount-partition()
{
    ( # subshell to keep options set by parameters local
	parse-mpparams "$@"
	case "${#mpparams[@]}" in
	    1)
		if [ -f "$1" ]; then
		    do-unmount-image "${mpparams[@]}"
		else
		    do-unmount-mountpoint "${mpparams[@]}"
		fi
		;;
	    2)  do-unmount-partition "${mpparams[@]}" ;;
	    3)  do-unmount-partition-verify "${mpparams[@]}" ;;
	    *)  mount-partition-usage ;;
	esac
    )
}

# When sourcing this script's functions into another script, the
# "load" parameter is needed to hide the calling scripts's parameters
# from the code below.
cmd="$1"
shift
case "$cmd" in
    mount*) mount-partition "$@" ;;
    umount*) umount-partition "$@" ;;
    load) : ;;
    *) mount-partition-usage
esac
