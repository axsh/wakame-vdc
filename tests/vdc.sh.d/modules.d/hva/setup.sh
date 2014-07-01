#!/bin/bash

set -e

hva_id=${hva_id:?"required variable: hva_id"}

echo "$(eval "echo \"$(cat ${modules_home}/hva.conf.tmpl)\"")" > $VDC_ROOT/tmp/hva-${hva_id}.conf
if [[ -n "${host}" ]]; then
  rsync ${VDC_ROOT}/tmp/hva-${hva_id}.conf ${host}:${VDC_ROOT}/tmp/hva-${hva_id}.conf
fi

exit 0
