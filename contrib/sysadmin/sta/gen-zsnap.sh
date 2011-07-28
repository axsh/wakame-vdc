#!/bin/bash
#
LANG=C
LC_ALL=C
PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin:/bin

set -e


#
#
#
usage() {
  cat <<EOS
usage:
 \$ $(basename $0) [ raw file ] [ snap uuid ]

ex.
 \$ $(basename $0) /path/to/ubuntu10.4_amd64.raw snap-lucid0
 \$ $(basename $0) /path/to/ubuntu10.4_amd64.raw snap-lucid0 --zsnap_prefix=/tmp
 \$ $(basename $0) /path/to/ubuntu10.4_amd64.raw snap-lucid0 --zsnap_prefix=/tmp --volume_prefix=xpool
EOS

  exit 1
}

got_error() {
  echo "[ERROR] error occured." >&2
  exit 1
}

#
# core arguments
#
raw_path=$1  # /export/path/to/images/ubuntu10.4_amd64.raw
snap_uuid=$2 # ubuntu64


#
# tests
#
[ -f ${raw_path} ] || {
  echo "no such file: ${raw_file}" >&2
  usage
}
[ -z ${snap_uuid} ] && {
  echo "snap_uuid is empty." >&2
  usage
}


#
# build option params
#
# via https://gist.github.com/368215
opts=""
# extract opts
for arg in $*; do
  case ${arg} in
    --*=*)
      key=${arg%%=*}; key=${key##--}
      value=${arg##--*=}
      eval ${key}=${value}
      opts="${opts} ${key}"
      ;;
  esac
done
unset opts


#
# constants
#
raw_file=$(basename ${raw_path})
volume_prefix=${volume_prefix:-rpool}
volume_path=${volume_prefix}/${raw_file}
volume_rdsk_prefix=/dev/zvol/rdsk
volume_rdsk_path=${volume_rdsk_prefix}/${volume_path}

snap_path=${volume_path}@${snap_uuid}
zsnap_prefix=${zsnap_prefix:-/tmp}
zsnap_file=${snap_uuid}.zsnap
zsnap_path=${zsnap_prefix}/${zsnap_file}



#
# main
#

######################################################################
#  zfs volume part
######################################################################
echo "Does volume exist? ${volume_path}."
zfs list ${volume_path} && {
  echo "Destroying volume ..."
  zfs destroy -r ${volume_path}
  echo "Destroyed volume. ${volume_path}."
  echo
  sleep 1
}

volume_size=$(du -b ${raw_path} | awk '{print $1}')
echo "Creating new volume ..."
zfs create -V ${volume_size} ${volume_path} || got_error
echo "Created new volume ${volume_path}."
sleep 1
echo

echo "Copying machine image ..."
time sudo nice dd if=${raw_path} of=${volume_rdsk_path} bs=1M || got_error
echo "Copied machine image. ${volume_rdsk_path}."
sleep 1
echo

echo "Syncing filesystem ..."
sync || got_error
echo "Synced filesystem."
sleep 1


######################################################################
# zfs volume snapshot part
######################################################################
echo "Does snapshot exist? ${snap_path}."
zfs list ${snap_path} 2>/dev/null && {
  echo
  echo "Exists. Destroying snapshot ..."
  zfs destroy ${snap_path} || got_error
  echo "Destroyed snapshot ${snap_path}."
}
sleep 1
echo

echo "Taking snapshot from volume ..."
zfs snapshot ${snap_path} || got_error
echo "Took snapshot ${snap_path}."
sleep 1
echo

echo "Sending zfs sream and generating zsnap ..."
zfs send ${volume_path}@${snap_uuid} > ${zsnap_path} || got_error
echo "Generated zsnap."
echo "=> ${zsnap_path}"
echo

echo "Cleaning up ...."
zfs destroy ${snap_path} || got_error
echo "Cleaned up."


exit 0
