#!/bin/bash

set -e

# config.env: sta_id

screen_it zfs-sta "cd ./dcmgr; CONF_PATH=../tmp/zfs-sta.conf ./bin/sta -i '${sta_id}' 2>&1 | tee ${tmp_path}/vdc-zfs-sta.log"
screen_it zfs-dav "${abs_path}/builder/conf/hup2term.sh httpd -X -f ${tmp_path}/apache-zfs.conf"

exit 0
