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
	drbd_devpath="${drbd_devpath}"
	lo_devpath="${lo_devpath}"
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

function rmraw() {
  [[ -f ${raw_path} ]] || : && rm -f ${raw_path}
}

function inodeinfo() {
  [[ -f ${raw_path} ]] && ls -i ${raw_path} | awk '{print $1}'
}

function lslodev() {
  local inode=$(inodeinfo)
  losetup -a | egrep ":${inode} " | awk -F: '{print $1}'
}

function maplodev() {
  local lo_devpath=${1:-$(losetup -f)}
  [[ -n "$(lslodev)" ]] || losetup ${lo_devpath} ${raw_path}
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
  local lo_devpath=${1:-$(losetup -f)}
  cat <<-EOS
	#
	# vdc_losetup_map="${raw_path} ${lo_devpath}"
	#
	resource ${name} {
	  protocol C;
	  device ${drbd_devpath};
	  disk   ${lo_devpath}; # raw_path=${raw_path}
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
  print_config ${lo_devpath} | tee ${config_path}
}

function del_config() {
  [[ -f ${config_path} ]] || : && rm -f ${config_path}
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
drbd_devpath=${drbd_devpath:-/dev/drbd9}
lo_devpath=${lo_devpath:-$(losetup -f)}
node0=${node0:-`hostname`:127.0.0.1} # [host]:[ip-addr]
port=${port:-7788}

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
  maplodev ${lo_devpath}
  gen_config
  setup_hosts_file
  ;;
install)
  drbdadm create-md ${name}
  ;;
assign::primary)
  drbdadm primary --force ${name}
  ;;
assign::secondary)
  drbdadm secondary ${name}
  ;;
clean)
  del_config
  unmaplodev
  rmraw
  ;;
*)
  usage
  ;;
esac
