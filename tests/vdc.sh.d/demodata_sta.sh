#!/bin/bash

set -e

vdc_data=${vdc_data:?"vdc_data needs to be set"}
sta_id=${sta_id:?"sta_id needs to be set"}
sta_server=${sta_server:-${ipaddr}}

hva_arch=$(uname -m)

cd ${VDC_ROOT}/dcmgr/

case ${sta_server} in
  ${ipaddr})
  shlog ./bin/vdc-manage storage iscsi add sta.${sta_id} \
    --uuid sn-${sta_id} \
    --base-path ${vdc_data}/volumes \
    --disk-space $((1024 * 1024)) \
    --ipaddr ${sta_server} \
    --snapshot-base-path ${vdc_data}/snap
 ;;
*)
  shlog ./bin/vdc-manage storage iscsi add sta.${sta_id} \
   --uuid sn-${sta_id} \
   --base-path xpool \
   --disk-space $((1024 * 1024)) \
   --ipaddr ${sta_server} \
   --snapshot-base-path /export/home/wakame/vdc/sta/snap
 ;;
esac
