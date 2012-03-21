#!/bin/bash

set -e

tmp_path="$VDC_ROOT/tmp"
account_id=${account_id:?"account_id needs to be set"}

cd ${VDC_ROOT}/dcmgr/

image_features_opts=
kvm -device ? 2>&1 | egrep 'name "lsi' -q || {
  image_features_opts="--virtio"
}

for meta in $data_path/image-*.meta; do
  (
    . $meta
    [[ -n "$localname" ]] || {
      localname=$(basename "$uri")
    }
    
    localpath=$tmp_path/images/$localname
    chksum=$(md5sum $localpath | cut -d ' ' -f1)
    
    case $storetype in
      "local")
        shlog ./bin/vdc-manage image add local ${localpath} \
          --md5sum $chksum \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "${localname} local" \
          --state init
        ;;
      
      "volume")
        shlog ./bin/vdc-manage image add volume snap-${uuid} \
          --md5sum ${chksum} \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "${localname} volume" \
          --state init
        ;;
    esac

    [[ -z "$image_features_opts" ]] || {
      shlog ./bin/vdc-manage image features wmi-${uuid} ${image_features_opts}
    }
  )
done
