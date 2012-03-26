#!/usr/bin/env bash
#
# Install script for Wakame-vdc
#

# force exit if script failed.
set +e

# track command execution
# please uncomment it for debug.
#trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

# print usage if -h option.
function usage {
  if [ -n "$*" ]; then
    echo ""
    echo "${progname}: $*"
  fi
cat <<_usage_
Usage: ${progname} [-h] operation [...]
 Operations:
    initdb              Initialize DB tables of wakame-vdc
    install 		Setup relative packages and setup environment.
    install-demo1	Setup demo configuration and images.
    help		Show this message and exit.
    run			Run Wakame-vdc.
    showvars		Show setup variables and exit.
 Options:
    -d             Skip distribution package install.
    -h             Print this help message.
    -H hypervisor  Set default hypervisor.  [Default: kvm]
    -s             Set without_screen=yes; run wakame-vdc without screen.
_usage_
  exit 1
}

###
# main
###

# initialize global variable
excode=0

# parse opts
_args=$@

# init option flag
opts='H:dsh'

# parse opts with getopts
getoptcmd='getopts ${opts} opt && opt=-${opt}'
optargcmd=':'
optremcmd='shift $((${OPTIND} -1))'

# parse command line options
while eval ${getoptcmd}; do
  case ${opt} in 
    -H)
      eval ${optargcmd}
      hypervisor=${OPTARG}
      ;;
    -d)
      without_distrib_pkg=yes
      ;;
    -s)
      without_screen=yes
      ;;
    -'?'|-h)
      usage
      ;;
  esac
done


# setup path
script_path=$(cd $(dirname $0) && pwd)
wakame_root=${wakame_root:-$(cd ${script_path}/../ && pwd)}
tmp_path=${wakame_root}/tmp
screenrc_path=${tmp_path}/screenrc

#include scripts
. $script_path/wakame_vars.sh
. $script_path/wakame_utils.sh
. $script_path/wakame_lib.sh

[[ $UID = 0 ]] || abort "Please run $0 with root privilege (e.g. su, sudo)"

# parse remained commands
eval ${optremcmd}

# if nothing, print usage
if [ -$# -eq 0 ]; then
  usage
  exit 0
fi 

# parse operations
while [ $# -gt 0 ]; do
  op=$1; shift
  operations="${operations} ${op}"
  
  case "${op}" in
  install)
    echo "Wakame-vdc install..."
    set_default_variables
    cleanup
    setup_base
    echo ""
    echo ""
    echo "==========================="
    echo "Wakame-vdc install done."
    echo "\"$0 run\" to run wakame-vdc"
    ;;
  showvars)
    echo "======== Variables ========"
    set
    echo "========= EnvVars ========="
    export
    exit
    ;;
  install-demo1)
    echo "Wakame-vdc demo1 install..."
    set_default_variables
    ${script_path}/wakame_demo1.sh
    echo "Wakame-vdc demo1 install done."
    ;;
  run)
    echo "Wakame-vdc running..."
    cleanup "force"
    set_default_variables
    run_standalone
    screen_attach
    screen_close
    [ -f "${tmp_path}/vdc-pid.log" ] && {
      wait $(cat ${tmp_path}/vdc-pid.log)
    }
    ;;
  initdb)
    echo -n "Wakame-vdc database is removed. OK? [Y/n]: "
    read yes_no
    if [ "${yes_no}" = "Y" -o "${yes_no}" = "y" ]; then
      echo "Initialize wakame-vdc database..."
      set_default_variables
      init_db
      echo "Initialize wakame-vdc database done."
    fi
    ;;
  *|help)
    usage
    ;;
  esac
done

# Kill zombi process... 
[ -f "${tmp_path}/vdc-pid.log" ] && {
  pids=$(cat ${tmp_path}/vdc-pid.log)
  [ -z "${pids}" ] || {
    for pid in ${pids}; do
      ps -p ${pid} >/dev/null 2>&1 && kill -HUP  ${pid}
    done
  }
}

exit $excode
