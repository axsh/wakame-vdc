#!/bin/bash

set -e

vdc_data=${vdc_data:?"vdc_data needs to be set"}
account_id=${account_id:?"account_id needs to be set"}

cd ${VDC_ROOT}/dcmgr/

image_features_opts=
[[ $hypervisor == "kvm" ]] && {
  image_features_opts="--virtio --acpi"
}

shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo1 --display-name="'local storage'" --base-uri="'file://${vdc_data}/images/'" --storage-type=local --description="'local backup storage under ${vdc_data}/images/'" --node-id="bksta.demo1"
shlog ./bin/vdc-manage backupstorage add --uuid bkst-demo2 --display-name="'webdav storage'" --base-uri="'http://localhost:8080/images/'" --storage-type=webdav --description="'nginx based webdav storage'" --node-id="bksta.demo2"

metalst=$(ls $data_path/image.enabled/image-*.meta || :)

if [[ -z "$metalst" ]]; then
  # Load all meta info from available/. backward compatibility.
  metalst=$(ls $data_path/image.available/image-*.meta)
fi

cat <<EOF
Image meta files to be registered:
>---------------------------------------<
$metalst
>---------------------------------------<
EOF

# download demo image files.
(
  cd ${vdc_data}/images

  if [[ ! -z "${remove_md5}" ]]; then
    # remove md5sum cache files.
    rm -f *.md5
  fi

  for meta in $metalst; do
    (
      . $meta
      [[ -n "$localname" ]] || {
        localname=$(basename "$uri")
      }

      echo "$(basename ${meta}), ${localname} ..."
      [[ -f "$localname" ]] || {
        # TODO: use HEAD and compare local cached file size
        echo "Downloading image file $localname ..."
        dnldname=$(basename "$uri")
        [[ -f "$dnldname" ]] || {
          time ${VDC_ROOT}/dcmgr/script/parallel-curl.sh --url="$uri" --output-path="$dnldname"
        }

       # Generate raw image file from .gz compressed (for download purposes) raw image file.
        [[ "${localname##*.}" != "gz" ]] && [[ "$container_format" = "none" ]] && {
          echo "gunzip $dnldname with keeping sparse area ..."
          time gunzip -c "$dnldname" | cp --sparse=always /dev/stdin "${localname}"
        }
        # do not remove .gz as they are used for gzipped file test cases.
        : # this line ensure the subshell exit with status code 0
      }
    )
  done
)

for meta in $metalst; do
  (
    . $meta
    [[ -n "$localname" ]] || {
      localname=$(basename "$uri")
    }

    localpath="${vdc_data}/images/${localname}"
    if [[ -f "${localpath}.md5" ]] && [[ "${localpath}.md5" -nt "${localpath}" ]]; then
      chksum=$(cat "${localpath}.md5")
    else
      echo "calculating checksum of $localpath ..."
      chksum=$(time md5sum "$localpath" | cut -d ' ' -f1 | tee "${localpath}.md5")
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

    os_type=${os_type:-'generic'}

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
	  --is-cacheable \
          --os-type "${os_type}"
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
	  --display-name "'${display_name}'" \
          --os-type "${os_type}"
        ;;
    esac

    [[ -z "$image_features_opts" ]] || {
      shlog ./bin/vdc-manage image features wmi-${uuid} ${image_features_opts}
    }
  )
done
