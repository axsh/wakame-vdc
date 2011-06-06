#!/bin/sh

export LANG=C
export LC_ALL=C
export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin:/bin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT

account_id=a-shpoolxx
snap_dir=/export/home/wakame/vdc/sta/snap
snap_uuid=lucid0r

vmimage_uuid=${snap_uuid}
vmimage_file=snap-${vmimage_uuid}.zsnap
vmimage_s3=http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz

# snapshot directory
[ -d ${snap_dir}/${account_id} ] || {
  mkdir -p ${snap_dir}/${account_id}
}
[ -f ${snap_dir}/${account_id}/${vmimage_file} ] || {
  cd ${snap_dir}/${account_id}
  wget ${vmimage_s3}
  gunzip ${vmimage_file}.gz
}


case $(uname -s)  in
  SunOS)
    myaddr=$(/sbin/ifconfig $(route get 1.1.1.1  | awk '$1 == "interface:" {print $2}') | awk '$1 == "inet" { print $2 }')
    ;;
  *)
    myaddr=
    ;;
esac

sta_ipv4=${myaddr:-##YOUR IPv4 ADDRESS##}

cat <<EOS | egrep -v '^#'
INSERT INTO storage_pools(
 account_id, uuid, created_at, updated_at, node_id, export_path, status,
 offering_disk_space, transport_type, storage_type, ipaddr, snapshot_base_path
)
VALUES (
  '${account_id}', 'demostor', now(), now(), 'sta-${sta_ipv4}', 'rpool', 'available',
  '102400', 'iscsi', 'zfs', '${sta_ipv4}', '${snap_dir}'
);

INSERT INTO volume_snapshots(
 account_id, uuid, storage_pool_id, origin_volume_id, size, status, state, created_at, updated_at
)
VALUES (
 '${account_id}', '${snap_uuid}', 1, '${snap_uuid}', 5120, 0, 'available', now(), now()
);

INSERT INTO images(
 account_id, uuid, created_at, updated_at, boot_dev_type, source, arch, description, state
VALUES (
 '${account_id}', '${snap_uuid}', now(), now(), 1, '--- \r\n:type: :vdcvol\r\n:snapshot_id: snap-${snap_uuid}\r\n', 'x86', NULL, 'init'
);
EOS

exit 0
