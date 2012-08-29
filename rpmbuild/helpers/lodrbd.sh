#!/bin/bash
#
# requires:
#  bash
#  tr, cat, tee, egrep, truncate, ls, losetup, awk, drbdadm
#
set -e

## private functions

function extract_args() {
  CMD_ARGS=
  for arg in $*; do
    case $arg in
      --*=*)
        key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
        value=${arg##--*=}
        eval "${key}=\"${value}\""
        ;;
      *)
        CMD_ARGS="${CMD_ARGS} ${arg}"
        ;;
    esac
  done
  # trim
  CMD_ARGS=${CMD_ARGS%% }
  CMD_ARGS=${CMD_ARGS## }
}

function usage() {
  cat <<-EOS
	usage:
	  $0 [command]

	options:
	  --name=sandbox
	  --node0=drbd01:192.0.2.11
	EOS
}

function dump_vers() {
  cat <<-EOS
	CMD_ARGS="${CMD_ARGS}"
	name="${name}"
	devpath="${devpath}"
	node0="${node0}"
	port="${port}"
	config_path="${config_path}"
	hosts_path="${hosts_path}"
	raw_path="${raw_path}"
	raw_size="${raw_size}"
	raw_unit="${raw_unit}"
	EOS
}

function mkraw() {
  [[ -f ${raw_path} ]] || truncate -s ${raw_size}${raw_unit} ${raw_path}
}

function inodeinfo() {
  [[ -f ${raw_path} ]] && ls -i ${raw_path} | awk '{print $1}'
}

function lslodev() {
  local inode=$(inodeinfo)
  losetup -a | egrep ":${inode} " | awk -F: '{print $1}'
}

function maplodev() {
  [[ -n "$(lslodev)" ]] || losetup $(losetup -f) ${raw_path}
}

function unmaplodev() {
  lslodev | while read lodev; do
    losetup -d ${lodev}
  done
}

function print_node_part() {
  local node=${1}
  cat <<-EOS
	  on ${node%%:*} {
	    address ${node##*:}:${port};
	  }
	EOS
}

function print_config() {
  local lodev_path=${1:-UNKNOWN}
  cat <<-EOS
	resource ${name} {
	  protocol C;
	  device ${devpath};
	  disk   ${lodev_path};
	  meta-disk internal;
	EOS

  for i in {0..9}; do
    eval local node=\$\{node${i}\}
    [[ -n "${node}" ]] && print_node_part ${node}
  done

  cat <<-EOS
	}
	EOS
}

function gen_config() {
  print_config $(lslodev) | tee ${config_path}
}

function setup_hosts_file() {
  [[ -f ${hosts_path} ]] || :
  for i in {0..9}; do
    eval local node=\$\{node${i}\}
    [[ -n "${node}" ]] && echo ${node##*:} ${node%%:*}
  done \
   | while read line; do
       egrep "^${line}\$" ${hosts_path} || echo ${line} >> ${hosts_path}
     done
}


## private variables

### prepare

extract_args $*

### read-only variables

readonly abs_path=$(cd $(dirname $0) && pwd)

### global variables

name=${name:-sandbox}
devpath=${devpath:-/dev/drbd0}
node0=${node0:-`hostname`:127.0.0.1} # [host]:[ip-addr]
port=${port:-7801}

config_path=${config_path:-/etc/drbd.d/${name}.res}
hosts_path=${hosts_path:-/etc/hosts}

raw_path=${raw_path:-/var/lib/wakame-vdc/drbd.${name}.raw}
raw_size=${raw_size:-10}
raw_unit=${raw_unit:-m}

cmd="$(echo ${CMD_ARGS} | sed "s, ,\n,g" | head -1)"

## main

case "${cmd}" in
dump|debug)
  echo inode:$(inodeinfo)
  dump_vers
  print_config
  ;;
setup)
  mkraw
  maplodev
  gen_config
  setup_hosts_file
  ;;
unmap)
  unmaplodev
  ;;
activate)
  drbdadm create-md ${name}
  /etc/init.d/drbd start
  ;;
primary)
  drbdadm primary --force ${name}
  ;;
secondary)
  drbdadm secondary ${name}
  ;;
*)
  usage
  ;;
esac
