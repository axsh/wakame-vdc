#!/bin/bash

set -x
set -e

abs_path=$(cd $(dirname $0) && pwd)
wakame_root=$(cd ${abs_path}/../../ && pwd)
log_dir=${abs_path}/logs

#
#
#
cd ${abs_path}
[ -d ${log_dir} ] || mkdir -p ${log_dir}

#
git pull
build_id=$(git log -n 1 --pretty=format:"%h")

function build_yum_repo () {
  time ./createrepo-vdc.sh 2>&1
  time yes | ./syncrepo-vdc.sh build 2>&1
  # upload vmapps to s3
  time ./build-s3-vmapp.sh 2>&1
}


case "$1" in
monthly|weekly)
  task=self-integrate
  ;;
daily)
  task=full-integrate
  ;;
hourly)
  task=soft-integrate
  ;;
*)
  task=soft-integrate
  ;;
esac

(
  BUILD_ID=${build_id} ./rules ${task}
  build_yum_repo
) 2>&1 | tee ${log_dir}/build.log.`date +%Y%m%d-%s` 2>&1
