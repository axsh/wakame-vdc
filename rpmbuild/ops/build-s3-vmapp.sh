#!/bin/bash

set -e
set -x

. ./config_s3.env
vmapp_dir=pool/vmapp/

./pickup-vmapp.sh

find ${vmapp_dir} -type f -name "wakame-*" -mtime +5 | sort | while read line; do
  rm -f ${line}
done

time s3cmd sync ${vmapp_dir} ${s3_repo_uri} --acl-public --check-md5 --dry-run
