#!/usr/bin/env bash
#

set +e

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
builder_path=${prefix_path}/tests/builder
tmp_path=${prefix_path}/tmp
screenrc_path=${tmp_path}/screenrc

. $builder_path/functions.sh

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

set_default_variables

mode=$1

cleanup

excode=0
case ${mode} in
  install)
    setup_base
    ;;
  init)
    init_db
    ;;
  cleanup)
    ;;
  multiple)
    set +e
    . builder/conf/nodes.conf
    cleanup_multiple
    run_multiple
    check_ready_multiple
    screen_attach
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    [ -f "${tmp_path}/vdc-pid.log" ] && {
      wait $(cat ${tmp_path}/vdc-pid.log)
    }
    ;;
  *)
    # interactive mode
    run_standalone
    screen_attach
    screen_close
    [ -f "${tmp_path}/vdc-pid.log" ] && {
      wait $(cat ${tmp_path}/vdc-pid.log)
    }
    ;;
esac

#
[ -f "${tmp_path}/vdc-pid.log" ] && {
  pids=$(cat ${tmp_path}/vdc-pid.log)
  [ -z "${pids}" ] || {
    for pid in ${pids}; do
      ps -p ${pid} >/dev/null 2>&1 && kill -HUP  ${pid}
    done
  }
}

exit $excode
