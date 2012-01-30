#!/bin/bash

set -e

vdc_root=${vdc_root?"vdc_root needs to be set"}

vmimage_snap_uuid=${vmimage_snap_uuid?"vmimage_snap_uuid needs to be set"}
vmimage_file=${vmimage_file?"vmimage_file needs to be set"}

dcmgr_dbname=${dcmgr_dbname?"dcmgr_dbname needs to be set"}
dcmgr_dbuser=${dcmgr_dbname?"dcmgr_dbuser needs to be set"}

account_id=${account_id?"account_id needs to be set"}
image_arch=${image_arch?"image_arch needs to be set"}

[ -d ${local_store_path} ] || {
  mkdir -p ${local_store_path}
}

function deploy_vmfile() {
  vmfile_basename=$1
  vmfile_uri=$2

  echo ${local_store_path}/${vmfile_basename}

  [ -f ${local_store_path}/${vmfile_basename} ] || {
    cd ${local_store_path}
    [ -f ${vmfile_basename}.gz ] || curl ${vmfile_uri} -o ${vmfile_basename}.gz
    echo generating ${vmfile_basename} ...
    zcat ${vmfile_basename}.gz | cp --sparse=always /dev/stdin ${vmfile_basename}
    sync
    du -hs                 ${vmfile_basename}
    du -hs --apparent-size ${vmfile_basename}
  }
}
deploy_vmfile ${vmimage_file}      ${vmimage_s3}

cat <<EOS | mysql -uroot ${dcmgr_dbname}
INSERT INTO volume_snapshots
 (account_id, uuid, storage_node_id, origin_volume_id, size, status, state, destination_key, deleted_at, created_at, updated_at)
values
 ('${account_id}', '${vmimage_snap_uuid}',      1, 'vol-${vmimage_snap_uuid}',      1024, 0, 'available', 'local@local:none:${local_store_path}/${vmimage_file}',      NULL, now(), now());
EOS

vmimage_md5=$(md5sum ${local_store_path}/${vmimage_file} | cut -d ' ' -f1)

cd ${vdc_root}/dcmgr
./bin/vdc-manage image add volume snap-${vmimage_snap_uuid} --md5sum ${vmimage_md5} --account-id ${account_id} --uuid wmi-${vmimage_snap_uuid} --arch ${images_arch} --description \" ${vmimage_snap_uuid} volume\" --state init
./bin/vdc-manage image features wmi-${vmimage_snap_uuid} --virtio
