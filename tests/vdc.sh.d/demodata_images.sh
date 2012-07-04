#!/bin/bash

set -e

tmp_path="$VDC_ROOT/tmp"
account_id=${account_id:?"account_id needs to be set"}

cd ${VDC_ROOT}/dcmgr/

image_features_opts=
kvm -device ? 2>&1 | egrep 'name "lsi' -q || {
  image_features_opts="--virtio"
}

shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo1 --display-name="'local storage'" --base-uri="'file://${VDC_ROOT}/tmp/images'" --storage-type=local --description="'local backup storage under ${VDC_ROOT}/tmp/images'"
shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo2 --display-name="'webdav storage'" --base-uri="'http://localhost:8080/images/'" --storage-type=webdav --description="'nginx based webdav storage'"

# download demo image files.
(
  cd $VDC_ROOT/tmp/images
  # remove md5sum cache files.
  rm -f *.md5

  for meta in $(ls $data_path/image-*.meta); do
    (
      . $meta
      [[ -n "$localname" ]] || {
        localname=$(basename "$uri")
      }
      echo "$(basename ${meta}), ${localname} ..."
      [[ -f "$localname" ]] || {
        # TODO: use HEAD and compare local cached file size
        echo "Downloading image file $localname ..."
        f=$(basename "$uri")
        curl "$uri" > "$f"
        # check if the file name has .gz.
        [[ "$f" == "${f%.gz}" ]] || {
          # gunzip with keeping sparse area.
          zcat "$f" | cp --sparse=always /dev/stdin "${f%.gz}"
        }
        [[ "${f%.gz}" == "$localname" ]] || {
          cp -p --sparse=always "${f%.gz}" "$localname"
        }
        # do not remove .gz as they are used for gzipped file test cases.
      }
    )
  done
)

for meta in $data_path/image-*.meta; do
  (
    . $meta
    [[ -n "$localname" ]] || {
      localname=$(basename "$uri")
    }

    localpath="${tmp_path}/images/${localname}"
    if [[ "$localpath" -nt "${localpath}.md5" ]]; then
      chksum=$(md5sum "$localpath" | cut -d ' ' -f1 | tee "${localpath}.md5")
    else
      chksum=$(cat "${localpath}.md5")
    fi
    alloc_size=$(ls -l "$localpath" | awk '{print $5}')
    if (file $localpath | grep ': gzip compressed data,' > /dev/null)
    then
      # get the uncompressed size embedded in the .gz file.
      size=$(gzip -l "$localpath" | awk -v fname="${localpath%.gz}" '$4 == fname {print $2}')
    else
      size=$alloc_size
    fi

    shlog ./bin/vdc-manage backupobject add \
      --storage-id=bkst-demo2 \
      --uuid bo-${uuid} \
      --display-name="'$localname'" \
      --object-key=$localname \
      --size=$size \
      --allocation-size=$alloc_size \
      --checksum="$chksum" \
      --description="'kvm 32bit'"
    
    case $storetype in
      "local")
        shlog ./bin/vdc-manage image add local "bo-${uuid}" \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "'${localname} local'" \
          --file-format ${file_format} \
          --root-device ${root_device} \
          --service-type ${service_type} \
          --is_public \
	  --display-name "'${display_name}'"
        ;;
      
      "volume")
        shlog ./bin/vdc-manage image add volume "bo-${uuid}" \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "'${localname} volume'" \
          --file-format ${file_format} \
          --root-device ${root_device} \
          --service-type ${service_type} \
          --is_public \
	  --display-name "'${display_name}'"
        ;;
    esac

    [[ -z "$image_features_opts" ]] || {
      shlog ./bin/vdc-manage image features wmi-${uuid} ${image_features_opts}
    }
  )
done
