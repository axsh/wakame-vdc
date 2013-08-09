# prepare direcotries under $VDC_ROOT/tmp.
for i in "${VDC_ROOT}/tmp/instances" "${VDC_ROOT}/tmp/snap/" "${VDC_ROOT}/tmp/images/" "${VDC_ROOT}/tmp/volumes/"  "${VDC_ROOT}/tmp/trema/log/" "${VDC_ROOT}/tmp/trema/pid/" "${VDC_ROOT}/tmp/trema/sock/"; do
  [[ -d "$i" ]] || mkdir -p $i
done

# Allow Apache to upload image files.
chown apache:apache "${VDC_ROOT}/tmp/images/"
