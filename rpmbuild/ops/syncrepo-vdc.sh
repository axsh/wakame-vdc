#!/bin/bash

set -e
set -x

. ./config_s3.env

[ -d ${rpm_dir} ] || mkdir -p ${rpm_dir}

case $1 in
build)
  cmd="s3cmd sync ${rpm_dir} ${s3_repo_uri} --delete-removed --acl-public --check-md5"
  ;;
backup)
  cmd="s3cmd sync ${s3_repo_uri} ${rpm_dir%%$(basename ${rpm_dir})} --check-md5"
  ;;
*)
  exit 0
  ;;
esac

${cmd} --dry-run
echo -n "sync? [y/n]"
read yorn
case ${yorn} in
[yY])
  ${cmd}
  ;;
*)
  ;;
esac
