#!/bin/bash

set -e

hma_id=${hma_id:?"required variable: hma_id"}

echo "$(eval "echo \"$(cat ${modules_home}/hma.conf.tmpl)\"")" > $VDC_ROOT/tmp/hma-${hma_id}.conf

exit 0
