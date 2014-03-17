#!/bin/bash

set -e

# config.env: host
# config.env: hva_id

screen_it_remote "hva-${hva_id}" $host - <<EOF
rvm use 2.0.0
cd ${VDC_ROOT}/dcmgr; CONF_PATH=../tmp/hva-${hva_id}.conf ./bin/hva -i '${hva_id}' -s '${amqp_server_uri}' 2>&1 | tee ${tmp_path}/vdc-${hva_id}.log
EOF

exit 0
