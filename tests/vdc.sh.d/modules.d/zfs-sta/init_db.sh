#!/bin/bash

set -e

# config.env: sta_id
sta_id=${sta_id:?"required variable: sta_id"}
ipaddr=${ipaddr:?"required variable: ipaddr"}

cd ${VDC_ROOT}/dcmgr/

shlog ./bin/vdc-manage storage iscsi add sta.${sta_id} \
    --uuid sn-${sta_id} \
    --disk-space $((1024 * 1024)) \
    --ipaddr ${ipaddr}

shlog ./bin/vdc-manage backupstorage add --uuid bkst-${sta_id} \
    --display-name="'webdav storage'" \
    --base-uri="'http://localhost:8080/images/'" \
    --storage-type="webdav" \
    --description="'webdav storage'" \
    --node-id="'bksta.${sta_id}'"

shlog ./bin/vdc-manage backupobject add \
    --storage-id=bkst-zfs1 \
    --uuid bo-imgzfs1 \
    --display-name="'zfs image1'" \
    --object-key="'vol-imgzfs2@bo-imgzfs2'" \
    --size=4096 \
    --allocation-size=782 \
    --checksum="deadbeaf" \
    --container-format="raw" \
    --description="'kvm 32bit'"

shlog ./bin/vdc-manage image add volume "bo-imgzfs1" \
    --account-id a-0000001 \
    --uuid wmi-imgzfs1 \
    --arch x86_64 \
    --description "'zfs image1'" \
    --file-format raw \
    --root-device uuid:148bc5df-3fc5-4e93-8a16-7328907cb1c0 \
    --service-type std \
    --is_public \
    --display-name "'zfs image1'"

shlog ./bin/vdc-manage image features "wmi-imgzfs1" --virtio


exit 0
