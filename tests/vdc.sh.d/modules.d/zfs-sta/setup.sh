#!/bin/bash

set -e

base_zpool=tank

echo "$(eval "echo \"$(cat ${modules_home}/httpd.conf.tmpl)\"")" > $VDC_ROOT/tmp/apache-zfs.conf
cp $modules_home/zfs-sta.conf $VDC_ROOT/tmp/zfs-sta.conf

exit 0
