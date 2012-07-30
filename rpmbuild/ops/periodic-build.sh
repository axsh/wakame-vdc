#!/bin/bash

set -x
set -e

abs_path=$(cd $(dirname $0) && pwd)
wakame_root=$(cd ${abs_path}/../../ && pwd)
log_dir=${abs_path}/logs
repo_uri=${repo_uri:-git://github.com/axsh/wakame-vdc.git}

#
#
#
cd ${abs_path}
[ -d ${log_dir} ] || mkdir -p ${log_dir}

#
function build_yum_repo () {
  time yes | ./syncrepo-vdc.sh backup 2>&1
  time       ./createrepo-vdc.sh 2>&1
  time yes | ./syncrepo-vdc.sh build 2>&1
}

# map task name
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
dry-run)
  task=dump-vers
  ;;
*)
  task=soft-integrate
  ;;
esac

function run_readonly_phase() {
  build_id=$(git log -n 1 --pretty=format:"%h")
  git show -p ${build_id}

  BUILD_ID=${build_id} REPO_URI=${repo_uri} ./rules ${task}
}

case "$1" in
dry-run)
  run_readonly_phase
  exit 0
  ;;
esac

(
git pull

run_readonly_phase
build_yum_repo

case "$1" in
monthly|weekly|daily)
  # upload vmapps to s3
  time ./build-s3-vmapp.sh 2>&1
  ;;
hourly)
  ;;
*)
  ;;
esac

) 2>&1 | tee ${log_dir}/build.log.`date +%Y%m%d-%s` 2>&1
