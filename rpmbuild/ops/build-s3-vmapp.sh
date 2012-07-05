#!/bin/bash

set -e
set -x

. ./config_s3.env
./pickup-vmapp.sh

find ${vmapp_dir} -type f -name "wakame-*" -mtime +5 | sort | while read line; do
  rm -f ${line}
done

time s3cmd sync ${vmapp_dir} ${s3_repo_uri} --delete-removed --acl-public --check-md5
