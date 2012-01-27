#!/bin/sh

set -e

vdc_root=${vdc_root?"vdc_root needs to be set"}

vmimage_snap_uuid=${vmimage_snap_uuid?"vmimage_snap_uuid needs to be set"}
vmimage_file=${vmimage_file?"vmimage_snap_uuid needs to be set"}

dcmgr_dbname=${dcmgr_dbname?"dcmgr_dbname needs to be set"}
dcmgr_dbuser=${dcmgr_dbname?"dcmgr_dbuser needs to be set"}
#dcmgr_dbpass=${dcmgr_dbpass}

account_id=${account_id?"account_id needs to be set"}
image_arch=${image_arch?"image_arch needs to be set"}

cat <<EOS | mysql -uroot ${dcmgr_dbname}
INSERT INTO volume_snapshots
 (account_id, uuid, storage_node_id, origin_volume_id, size, status, state, destination_key, deleted_at, created_at, updated_at)
values
 ('${account_id}', '${vmimage_snap_uuid}',      1, 'vol-${vmimage_snap_uuid}',      1024, 0, 'available', 'local@local:none:${vmimage_file}',      NULL, now(), now());
EOS

vmimage_md5=$(md5sum ${vmimage_file} | cut -d ' ' -f1)

cd ${vdc_root}/dcmgr
./bin/vdc-manage image add volume snap-${vmimage_snap_uuid} --md5sum ${vmimage_md5} --account-id ${account_id} --uuid wmi-${vmimage_snap_uuid} --arch ${images_arch} --description \" ${vmimage_snap_uuid} volume\" --state init
./bin/vdc-manage image features wmi-${vmimage_snap_uuid} --virtio
