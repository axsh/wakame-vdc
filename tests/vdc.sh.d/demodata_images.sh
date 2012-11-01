#!/bin/bash

set -e

vdc_data=${vdc_data:?"vdc_data needs to be set"}
account_id=${account_id:?"account_id needs to be set"}

cd ${VDC_ROOT}/dcmgr/

image_features_opts=
kvm -device ? 2>&1 | egrep 'name "lsi' -q || {
  image_features_opts="--virtio"
}

shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo1 --display-name="'local storage'" --base-uri="'file://${vdc_data}/images/'" --storage-type=local --description="'local backup storage under ${vdc_data}/images/'"
shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo2 --display-name="'webdav storage'" --base-uri="'http://localhost:8080/images/'" --storage-type=webdav --description="'nginx based webdav storage'"

# download demo image files.
(
  cd ${vdc_data}/images
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
        [[ -f "$f" ]] || {
          time ${VDC_ROOT}/dcmgr/script/parallel-curl.sh --url="$uri" --output-path="$f"
        }

       # Generate raw image file from .gz compressed image file.
        [[ "$f" != "${f%.gz}" ]] && [[ "$container_format" = "none" ]] && {
          echo "gunzip $f with keeping sparse area ..."
          time gunzip -c "$f" | cp --sparse=always /dev/stdin "${localname}"
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

    localpath="${vdc_data}/images/${localname}"
    if [[ "$localpath" -nt "${localpath}.md5" ]]; then
      echo "calculating checksum of $localpath ..."
      chksum=$(time md5sum "$localpath" | cut -d ' ' -f1 | tee "${localpath}.md5")
    else
      chksum=$(cat "${localpath}.md5")
    fi
    alloc_size=$(ls -l "$localpath" | awk '{print $5}')

    case "$container_format" in
      "gz")
        echo "get the uncompressed size embedded in the .gz file $localpath ..."
        size=$(gzip -l "$localpath" | awk -v fname="${localpath%.gz}" '$4 == fname {print $2}')
        ;;
      "tgz")
        size=$(tar -ztvf "$localpath" | awk -v fname="${localname%.tar.gz}" '$6 == fname {print $3}')
        ;;
      "tar")
        size=$(tar -tvf "$localpath" | awk -v fname="${localname%.tar}" '$6 == fname {print $3}')
        ;;
      *)
        size=$alloc_size
        ;;
    esac

    [[ -z "$size" ]] && { echo "Failed to get original size" 1>&2; exit 1; }

    shlog ./bin/vdc-manage backupobject add \
      --storage-id=bkst-demo2 \
      --uuid bo-${uuid} \
      --display-name="'$localname'" \
      --object-key=$localname \
      --size=$size \
      --allocation-size=$alloc_size \
      --checksum="$chksum" \
      --container-format="$container_format" \
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
	  --display-name "'${display_name}'" \
	  --is-cacheable
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
