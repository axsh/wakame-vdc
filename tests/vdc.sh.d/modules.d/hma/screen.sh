#!/bin/bash

set -e

# config.env: hma_id

screen_it "hma-${hma_id}" "cd ${VDC_ROOT}/dcmgr; CONF_PATH=../tmp/hma-${hma_id}.conf ./bin/hma -i '${hma_id}' -s '${amqp_server_uri}' 2>&1 | tee ${tmp_path}/vdc-${hma_id}.log"

exit 0
