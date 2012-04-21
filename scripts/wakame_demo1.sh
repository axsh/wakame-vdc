#!/bin/bash
#
# wakame-vdc demo1 config/image installation script.
#

set -e

script_path=$(cd $(dirname $0) && pwd)
wakame_root=${wakame_root:-$(cd ${script_path}/../ && pwd)}
. $script_path/wakame_vars.sh
. $script_path/wakame_utils.sh

tmp_path="${wakame_root}/tmp"
data_path="${wakame_root}/tests/vdc.sh.d"
account_id=${account_id:?"account_id needs to be set"}

hypervisor=${hypervisor:?"hypervisor needs to be set"}

hva_arch=$(uname -m)

cd ${wakame_root}/dcmgr/

shlog ./bin/vdc-manage host add hva.demo1 \
  --force \
  --uuid hn-demo1 \
  --account-id ${account_id} \
  --cpu-cores 100 \
  --memory-size 400000 \
  --hypervisor ${hypervisor} \
  --arch ${hva_arch}

case ${sta_server} in
  ${ipaddr})
  shlog ./bin/vdc-manage storage add sta.demo1 \
    --force \
    --uuid sn-demo1 \
    --account-id ${account_id} \
    --base-path ${tmp_path}/volumes \
    --disk-space $((1024 * 1024)) \
    --ipaddr ${sta_server} \
    --storage-type raw \
    --snapshot-base-path ${tmp_path}/snap

  #ln -fs ${vmimage_path}      ${vmimage_snap_path}
  #ln -fs ${vmimage_meta_path} ${vmimage_meta_snap_path}
 ;;
*)
  shlog ./bin/vdc-manage storage add sta.demo1 \
   --force \
   --uuid sn-demo1 \
   --account-id ${account_id} \
   --base-path xpool \
   --disk-space $((1024 * 1024)) \
   --ipaddr ${sta_server} \
   --storage-type zfs \
   --snapshot-base-path /export/home/wakame/vdc/sta/snap
 ;;
esac

# vlan
#shlog ./bin/vdc-manage vlan    add --tag-idb 1      --uuid vlan-demo1    --account-id ${account_id}
#shlog ./bin/vdc-manage network add           --uuid   nw-demo1    --ipv4-gw ${ipv4_gw} --prefix ${prefix_len} --domain vdc.local --dns ${dns_server} --dhcp ${dhcp_server} --metadata ${metadata_server} --metadata-port ${metadata_port} --vlan-id 1 --description demo
# non vlan
shlog ./bin/vdc-manage network add \
 --uuid nw-demo1 \
 --ipv4-network ${ipv4_gw} \
 --ipv4_gw ${ipv4_gw} \
 --prefix ${prefix_len} \
 --domain vdc.local \
 --dns ${dns_server} \
 --dhcp ${dhcp_server} \
 --metadata ${metadata_server} \
 --metadata-port ${metadata_port} \
 --description demo \
 --link-interface br0
shlog ./bin/vdc-manage network add \
 --uuid nw-demo2 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10 --link-interface br0
shlog ./bin/vdc-manage network add \
 --uuid nw-demo3 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10 --link-interface br0
shlog ./bin/vdc-manage network add \
 --uuid nw-demo4 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo5 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10
# physical network
shlog ./bin/vdc-manage network phy add eth0 --interface eth0
# bridge only closed network
shlog ./bin/vdc-manage network phy add null1 --null
shlog ./bin/vdc-manage network phy add null2 --null
# set forward interface(= physical network) from network
shlog ./bin/vdc-manage network forward nw-demo1 eth0
shlog ./bin/vdc-manage network forward nw-demo2 eth0
shlog ./bin/vdc-manage network forward nw-demo3 eth0
shlog ./bin/vdc-manage network forward nw-demo4 null1
shlog ./bin/vdc-manage network forward nw-demo5 null2

[ -f /etc/redhat-release ] && {
  # rhel
  gw_dev=$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $5}')
  ipaddr=$(/sbin/ip addr show ${gw_dev} | grep -w inet | awk '{print $2}')
  [ -n "${range_begin}" ] || range_begin=`ipcalc -n ${ipaddr}/${prefix_len} | sed 's,.*=,,'`
  [ -n "${range_end}"   ] || range_end=`ipcalc -b ${ipaddr}/${prefix_len} | sed 's,.*=,,'`
} || {
  # ubuntu
  [ -n "${range_begin}" ] || range_begin=`ipcalc ${ipv4_gw}/${prefix_len} | awk '$1 == "HostMin:" { print $2 }'`
  [ -n "${range_end}"   ] || range_end=`ipcalc ${ipv4_gw}/${prefix_len} | awk '$1 == "HostMax:" { print $2 }'`
}

shlog ./bin/vdc-manage network dhcp addrange nw-demo1 $range_begin $range_end
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.61 10.100.0.65
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.70 10.100.0.75
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.68 10.100.0.75 # range prepend
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.72 10.100.0.80 # range append
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.60 10.100.0.80 # range merge
shlog ./bin/vdc-manage network dhcp addrange nw-demo3 10.101.0.60 10.101.0.80
shlog ./bin/vdc-manage network dhcp addrange nw-demo4 10.100.0.100 10.100.0.130
shlog ./bin/vdc-manage network dhcp addrange nw-demo5 10.101.0.100 10.101.0.130

shlog ./bin/vdc-manage tag map tag-shhost hn-demo1
shlog ./bin/vdc-manage tag map tag-shstor sn-demo1
shlog ./bin/vdc-manage tag map tag-shnet  nw-demo1

shlog ./bin/vdc-manage network reserve nw-demo1 --ipv4=${ipaddr}

shlog ./bin/vdc-manage spec  add --uuid is-demospec --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 1 --memory-size 256 --weight 1
shlog ./bin/vdc-manage spec  add --uuid is-demo2    --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 2 --memory-size 256 --weight 1
shlog ./bin/vdc-manage spec  addvif is-demo2 eth1
shlog ./bin/vdc-manage spec  addvif is-demo2 eth2

shlog ./bin/vdc-manage securitygroup add --uuid  sg-demofgr --account-id ${account_id} --description demo
shlog ./bin/vdc-manage securitygroup modify sg-demofgr --rule=- <<EOF
tcp:22,22,ip4:0.0.0.0
EOF
shlog ./bin/vdc-manage securitygroup modify sg-demofgr --rule=- <<EOF
tcp:22,22,ip4:0.0.0.0
tcp:80,80,ip4:0.0.0.0
EOF
shlog ./bin/vdc-manage securitygroup modify sg-demofgr --rule=- <<EOF
# demo rule for demo instances
tcp:22,22,ip4:0.0.0.0
tcp:80,80,ip4:0.0.0.0
udp:53,53,ip4:0.0.0.0
icmp:-1,-1,ip4:0.0.0.0
EOF

# change *.pem permission
chmod 600 $data_path/pri.pem
chmod 600 $data_path/pub.pem
shlog ./bin/vdc-manage keypair add --account-id ${account_id} --uuid ssh-demo --private-key=$data_path/pri.pem --public-key=$data_path/pub.pem --description "demo key1"

cat <<EOS | mysql -uroot ${dcmgr_dbname}
INSERT INTO volume_snapshots values
 (1, '${account_id}', 'lucid1', 1, 'vol-lucid1', 1024, 0, 'available', 'local@local:none:${wakame_root}/tmp/images/ubuntu-lucid-kvm-32.raw', NULL, now(), now()),
 (2, '${account_id}', 'lucid6', 1, 'vol-lucid6', 1024, 0, 'available', 'local@local:none:${wakame_root}/tmp/images/ubuntu-lucid-kvm-ms-32.raw', NULL, now(), now());
EOS

image_features_opts=
kvm -device ? 2>&1 | egrep 'name "lsi' -q || {
  image_features_opts="--virtio"
}

for meta in $data_path/image-*.meta; do
  (
    . $meta
    [[ -n "$localname" ]] || {
      localname=$(basename "$uri")
    }
    
    localpath=$tmp_path/images/$localname
    chksum=$(md5sum $localpath | cut -d ' ' -f1)
    
    case $storetype in
      "local")
        shlog ./bin/vdc-manage image add local ${localpath} \
          --md5sum $chksum \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "${localname} local" \
          --state init
        ;;
      
      "volume")
        shlog ./bin/vdc-manage image add volume snap-${uuid} \
          --md5sum ${chksum} \
          --account-id ${account_id} \
          --uuid wmi-${uuid} \
          --arch ${arch} \
          --description "${localname} volume" \
          --state init
        ;;
    esac

    [[ -z "$image_features_opts" ]] || {
      shlog ./bin/vdc-manage image features wmi-${uuid} ${image_features_opts}
    }
  )
done

exit 0
