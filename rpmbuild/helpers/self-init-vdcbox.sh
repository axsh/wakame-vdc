#!/bin/bash
#
#set -e
set -x
export LANG=C

## VDC_*
VDC_SYSDEFAULT_CONFIG=${VDC_SYSDEFAULT_CONFIG:-/etc/default/wakame-vdc}
VDC_SELFTEST_HYPERVISOR=${VDC_SELFTEST_HYPERVISOR:-openvz}

# keep i686 archtecture for dataset "demo1"
VDC_VBOX_ARCH=i686

## MYSQL_*
MYSQL_LIBDIR=/var/lib/mysql


[[ -f ${VDC_SYSDEFAULT_CONFIG} ]] || {
  echo "no such file: ${VDC_SYSDEFAULT_CONFIG}" >&2
  exit 1
}
. ${VDC_SYSDEFAULT_CONFIG}

export HOME=${VDC_ROOT}


## mysqld
function start_mysqld() {
  /etc/init.d/mysqld start
}
function stop_mysqld() {
  /etc/init.d/mysqld stop
}
function init_mysqld() {
  # [[ -d ${MYSQL_LIBDIR} ]] && rm -rf ${MYSQL_LIBDIR}
  # mysql_install_db
  :
}
function force_cleanup_mysqld() {
  stop_mysqld
  init_mysqld
  start_mysqld
}

## vdcbox_vdc
function stop_vdcbox_vdc() {
  initctl stop vdc-hva
  initctl stop vdc-collector
}
function start_vdcbox_vdc() {
  initctl start vdc-collector
  initctl start vdc-hva
}

## vdcbox_demo
function cleanup_vdcbox_demo() {
  for i in {0..5}; do
    echo ... waiting ${i}
    stop_vdcbox_vdc
    sleep 1
  done
  force_cleanup_mysqld
}
function stop_vdcbox_demo() {
  echo "Stopping vdcbox demo."
  stop_vdcbox_vdc
  echo "Stopped vdcbox demo."
}
function start_vdcbox_demo() {
  echo "Starting vdcbox demo."
  start_vdcbox_vdc
  echo "Started vdcbox demo."
}
function init_vdcbox_demo() {
  echo "Initializing vdcbox demo."
  cleanup_vdcbox_demo
  cd ${VDC_ROOT}/tests
  time hypervisor=${VDC_SELFTEST_HYPERVISOR} setarch ${VDC_VBOX_ARCH} ./vdc.sh init
  echo "Initialized vdcbox demo."
}

##
case "${1}" in
start) start_vdcbox_demo ;;
stop)   stop_vdcbox_demo ;;
init)   init_vdcbox_demo ;;
*) ;;
esac
