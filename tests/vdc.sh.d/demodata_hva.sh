#!/bin/bash

set -e

hypervisor=${hypervisor:?"hypervisor needs to be set"}

hva_id=${hva_id:?"hva_id needs to be set"}
hva_arch=${hva_arch:?"hva_arch needs to be set"}

cd ${VDC_ROOT}/dcmgr/

shlog ./bin/vdc-manage host add hva.demo1 \
  --force \
  --uuid hn-demo1 \
  --cpu-cores 100 \
  --memory-size 400000 \
  --hypervisor ${hypervisor} \
  --arch ${hva_arch}

shlog ./bin/vdc-manage host add hva.demo2 \
  --force \
  --uuid hn-demo2 \
  --cpu-cores 100 \
  --memory-size 400000 \
  --hypervisor ${hypervisor} \
  --arch ${hva_arch}
