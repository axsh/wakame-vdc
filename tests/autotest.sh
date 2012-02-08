#!/usr/bin/env bash

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
builder_path=${prefix_path}/tests/builder
tmp_path=${prefix_path}/tmp
screenrc_path=${tmp_path}/screenrc

. $builder_path/functions.sh

mode=$1
scenario=$2

[ -z ${mode} ] && abort "Usage: "$0" install|standalone [scenario]|multiple [scenario]|openflow [scenario]|build_cd"

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

set_default_variables

cleanup

excode=0
case ${mode} in
  install)
    setup_base
    ;;
  standalone)
    (
     set +e
     run_standalone
     check_ready_standalone
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  multiple)
    (
     set +e
     . builder/conf/nodes.conf
     cleanup_multiple
     run_multiple
     check_ready_multiple
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  openflow)
    # disable shell exit on error which caused by test cases.
    (
     set +e
     with_openflow=yes
     run_standalone
     check_ready_standalone
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  build_cd)
    # build image
    cd_builder_dir="${prefix_path}/tests/cd_builder"
    build_image_file="ubuntu-10.04.3-server-amd64.iso"
    build_image="/var/tmp/${build_image_file}"
    build_image_source="http://releases.ubuntu.com/lucid/${build_image_file}"
    builded_image="${cd_builder_dir}/wakame-vdc-*-amd64.iso"

    ( 
      set +e
      #check_ready_standalone

      cd "${cd_builder_dir}"

      # run build iso image.
      [[ ! -e "${build_image}" ]] && { 
        ${prefix_path}/dcmgr/script/pararell-curl.sh --url=${build_image_source} --output_path=$build_image
      }

      if [ -e "${build_image}" ]; then
        ./build_cd.sh --without-gpg-sign ${build_image}
        rm ${builded_image}
        
      else
        abort "Couldn't find ${build_image}"
      fi
      
    )
    excode=$?
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
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
