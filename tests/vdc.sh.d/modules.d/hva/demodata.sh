#!/bin/bash

set -e

# config.env
hypervisor=${hypervisor:?"hypervisor needs to be set"}
hva_id=${hva_id:?"hva_id needs to be set"}

cd ${VDC_ROOT}/dcmgr/

hva_arch=$(uname -m)
case ${hva_arch} in
x86_64) ;;
  i*86) hva_arch=x86 ;;
     *) ;;
esac

shlog ./bin/vdc-manage host add hva.${hva_id} \
  --force \
  --uuid hn-${hva_id} \
  --cpu-cores 100 \
  --memory-size 400000 \
  --disk-space  500000 \
  --hypervisor ${hypervisor} \
  --arch ${hva_arch}

exit 0
