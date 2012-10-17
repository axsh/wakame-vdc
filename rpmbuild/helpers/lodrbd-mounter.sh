#!/bin/bash
#
# requires:
#  bash
#  losetup, egrep, sed, mount, umount, runlevel, awk, find
#
set -e

## environment variables

export LANG=C
export LC_ALL=C
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

## private functions

function sysv_start() {
  local raw_path=$1 lo_devpath=$2
  losetup -a | egrep -w ${raw_path} && {
    echo "already mapped: ${raw_path} -> ${lo_devpath}"
  } || {
    losetup ${lo_devpath} ${raw_path}
  }
}

function sysv_stop() {
  local raw_path=$1 lo_devpath=$2
  mount | egrep ${raw_path} -q && {
    umount     ${lo_devpath}
    losetup -d ${lo_devpath}
  }
}

function extract_losetup_map() {
  local config_path=$1
  [[ -f ${config_path} ]] || return 1
  embeded_param=$(egrep ^# ${config_path} | sed "s,^# ,," | egrep ^vdc_losetup_map=)
  [[ -z "${embeded_param}" ]] && return 1
  eval ${embeded_param}
  echo ${vdc_losetup_map}
}

function detect_runlevel() {
  runlevel | awk '{print $2}'
}

function lsdrbdconf() {
  [[ -d ${drbd_conf_d} ]] || return 1
  find ${drbd_conf_d} -maxdepth 1 -type f -name ${drbd_conf_pattern}
}

## private variables

drbd_conf_d=${drbd_conf_d:-/etc/drbd.d}
drbd_conf_pattern=${drbd_conf_pattern:-*.res}

## main

lsdrbdconf | while read config_path; do
  echo === ${config_path} ===

  losetup_map=$(extract_losetup_map ${config_path})
  # => /var/lib/wakame-vdc/drbd.rabbitmq.raw /dev/loop7

  runlevel="$(detect_runlevel)"
  echo runlevel:${runlevel}

  case "${runlevel}" in
  [2345]) sysv_start ${losetup_map} ;;
  [016])  sysv_stop  ${losetup_map} ;;
  *) ;;
  esac
done
