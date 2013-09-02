#!/bin/bash

set -e

# prepare configuration files

# dcmgr
(
  cd ${VDC_ROOT}/dcmgr/config/
  cp -f dcmgr.conf.example dcmgr.conf
  cp -f snapshot_repository.yml.example snapshot_repository.yml
  cp -f nsa.conf.example nsa.conf
  cp -f sta.conf.example sta.conf

  echo "$(eval "echo \"$(cat $VDC_ROOT/tests/vdc.sh.d/apache-proxy.conf.tmpl)\"")" > $VDC_ROOT/tmp/apache-proxy.conf
  echo "$(eval "echo \"$(cat $VDC_ROOT/tests/vdc.sh.d/nginx-proxy.conf.tmpl)\"")" > $VDC_ROOT/tmp/nginx-proxy.conf
  echo "$(eval "echo \"$(cat $VDC_ROOT/tests/vdc.sh.d/hva.conf.tmpl)\"")" > hva.conf

  cd ${VDC_ROOT}/dcmgr/config/convert_specs/
  cp -f load_balancer.yml.example load_balancer.yml
)
