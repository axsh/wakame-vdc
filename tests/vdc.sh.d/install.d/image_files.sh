# download demo image files.
(
  cd $VDC_ROOT/tmp/images
  
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
