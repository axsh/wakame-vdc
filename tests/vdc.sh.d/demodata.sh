#!/bin/bash

set -e

tmp_path="$VDC_ROOT/tmp"
account_id=${account_id:?"account_id needs to be set"}

hypervisor=${hypervisor:?"hypervisor needs to be set"}

# networks table
ipv4_gw=${ipv4_gw:?"ipv4_gw needs to be set"}
prefix_len="${prefix_len:-$(/sbin/ip route show | awk '$9 == ip { sub(/.*\//, "", $1); print $1; }' ip=$ipaddr)}"

dns_server=${dns_server:-${ipaddr}}
dhcp_server=${dhcp_server:-${ipaddr}}
metadata_server=${metadata_server:-${ipaddr}}

node_id=${node_id:-"demo1"}

hva_arch=$(uname -m)
case ${hva_arch} in
x86_64) ;;
  i*86) hva_arch=x86 ;;
     *) ;;
esac

(hva_id=${node_id} hva_arch=${hva_arch} . $data_path/demodata_hva.sh)
(sta_id=${node_id} sta_server=${sta_server:-${ipaddr}} . $data_path/demodata_sta.sh)

cd ${VDC_ROOT}/dcmgr/

# Physical network definitions
shlog ./bin/vdc-manage network dc add public
shlog ./bin/vdc-manage network dc add-network-mode public securitygroup
shlog ./bin/vdc-manage network dc del-network-mode public passthru
# bridge only closed network
shlog ./bin/vdc-manage network dc add null1
shlog ./bin/vdc-manage network dc add null2

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
 --description demo
shlog ./bin/vdc-manage network add \
 --uuid nw-demo2 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo3 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo4 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo5 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo6 \
 --ipv4-network 10.102.0.0 \
 --ipv4_gw 10.102.0.1 \
 --prefix 24 \
 --domain vnet6.local \
 --metric 10
shlog ./bin/vdc-manage network add \
 --uuid nw-demo7 \
 --ipv4-network 10.103.0.0 \
 --ipv4_gw 10.103.0.1 \
 --prefix 24 \
 --domain vnet7.local \
 --metric 10

# set forward interface(= physical network) from network
shlog ./bin/vdc-manage network forward nw-demo1 public
shlog ./bin/vdc-manage network forward nw-demo2 public
shlog ./bin/vdc-manage network forward nw-demo3 public
shlog ./bin/vdc-manage network forward nw-demo4 null1
shlog ./bin/vdc-manage network forward nw-demo5 null2
shlog ./bin/vdc-manage network forward nw-demo6 null1
shlog ./bin/vdc-manage network forward nw-demo7 null1

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

shlog ./bin/vdc-manage network service dhcp nw-demo6 --ipv4=10.102.0.2
shlog ./bin/vdc-manage network service dhcp nw-demo7 --ipv4=10.103.0.2
shlog ./bin/vdc-manage network service dns nw-demo7 --ipv4=10.103.0.2

shlog ./bin/vdc-manage network dhcp addrange nw-demo1 $range_begin $range_end
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.61 10.100.0.65
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.70 10.100.0.75
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.68 10.100.0.75 # range prepend
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.72 10.100.0.80 # range append
shlog ./bin/vdc-manage network dhcp addrange nw-demo2 10.100.0.60 10.100.0.80 # range merge
shlog ./bin/vdc-manage network dhcp addrange nw-demo3 10.101.0.60 10.101.0.80
shlog ./bin/vdc-manage network dhcp addrange nw-demo4 10.100.0.100 10.100.0.130
shlog ./bin/vdc-manage network dhcp addrange nw-demo5 10.101.0.100 10.101.0.130
shlog ./bin/vdc-manage network dhcp addrange nw-demo6 10.102.0.10 10.102.0.240
shlog ./bin/vdc-manage network dhcp addrange nw-demo7 10.103.0.10 10.103.0.240

shlog ./bin/vdc-manage tag map tag-shhost hn-${node_id}
shlog ./bin/vdc-manage tag map tag-shstor sn-${node_id}
shlog ./bin/vdc-manage tag map tag-shnet  nw-demo1

shlog ./bin/vdc-manage network reserve nw-demo1 --ipv4=${ipaddr}

shlog ./bin/vdc-manage spec  add --uuid is-demospec --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 1 --memory-size 256 --quota-weight 1
shlog ./bin/vdc-manage spec  add --uuid is-demo2    --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 2 --memory-size 256 --quota-weight 1
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

shlog ./bin/vdc-manage keypair add --account-id ${account_id} --uuid ssh-demo --private-key=$data_path/pri.pem --public-key=$data_path/pub.pem --description "demo key1"

cat <<EOS | mysql -uroot ${dcmgr_dbname}
INSERT INTO volume_snapshots values
 (1, '${account_id}', 'lucid1', 1, 'vol-lucid1', 1024, 0, 'available', 'local@local:none:${VDC_ROOT}/tmp/images/ubuntu-lucid-kvm-32.raw', NULL, now(), now(), 'std'),
 (2, '${account_id}', 'lucid6', 1, 'vol-lucid6', 1024, 0, 'available', 'local@local:none:${VDC_ROOT}/tmp/images/ubuntu-lucid-kvm-ms-32.raw', NULL, now(), now(), 'std');
EOS

(. $data_path/demodata_images.sh)

exit 0
