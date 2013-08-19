#!/bin/bash

set -e

hypervisor=${hypervisor:?"hypervisor needs to be set"}

hva_id=${hva_id:?"hva_id needs to be set"}
hva_arch=${hva_arch:?"hva_arch needs to be set"}

cd ${VDC_ROOT}/dcmgr/

shlog ./bin/vdc-manage host add hva.${hva_id} \
  --force \
  --uuid hn-${hva_id} \
  --cpu-cores 100 \
  --memory-size 400000 \
  --disk-space  500000 \
  --hypervisor ${hypervisor} \
  --arch ${hva_arch}
