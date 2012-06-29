#!/bin/bash

set -e
set -x

owner=$(whoami)

archs="x86_64 i686"
vmapp_dir=pool/vmapp/
s3_repo_uri=s3://dlc.wakame.axsh.jp/demo/vmapp/rhel/6/

./pickup-vmapp.sh

find ${vmapp_dir} -type f -name "wakame-*" -mtime +5 | sort | while read line; do
  rm -f ${line}
done

time s3cmd sync ${vmapp_dir} ${s3_repo_uri} --delete-removed --acl-public --check-md5
