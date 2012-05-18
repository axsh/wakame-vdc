# prepare direcotries under $VDC_ROOT/tmp.
for i in "${VDC_ROOT}/tmp/instances" "${VDC_ROOT}/tmp/snap/" "${VDC_ROOT}/tmp/images/" "${VDC_ROOT}/tmp/volumes/"  "${VDC_ROOT}/tmp/trema/log/" "${VDC_ROOT}/tmp/trema/pid/" "${VDC_ROOT}/tmp/trema/sock/" "${VDC_ROOT}/tmp/backups"; do
  [[ -d "$i" ]] || mkdir -p $i
done
