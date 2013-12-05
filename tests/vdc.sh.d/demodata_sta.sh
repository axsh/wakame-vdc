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
    --disk-space $((1024 * 1024)) \
    --ipaddr ${sta_server} \
 ;;
*)
  shlog ./bin/vdc-manage storage iscsi add sta.${sta_id} \
   --uuid sn-${sta_id} \
   --disk-space $((1024 * 1024)) \
   --ipaddr ${sta_server} \
 ;;
esac
