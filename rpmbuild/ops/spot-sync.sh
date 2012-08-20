#!/bin/bash

set -e
set -x

release_id=$(../helpers/gen-release-id.sh)
[[ -d ${release_id} ]] || exit 1

rpm_dir=${release_id}
s3_repo_uri=s3://dlc.wakame.axsh.jp/packages/rhel/6-spot/
cmd="s3cmd sync ${rpm_dir} ${s3_repo_uri} --acl-public --check-md5"
echo ${cmd}
eval ${cmd}
