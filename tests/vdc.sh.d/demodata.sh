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

(. $data_path/demodata_images.sh)


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

range_begin=192.168.64.100
range_end=192.168.64.200

# must keep the permission 600
#
# > @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# > @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
# > @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# > Permissions 0644 for '/path/to/wakame-vdc/tests/vdc.sh.d/pri.pem' are too open.
# > It is recommended that your private key files are NOT accessible by others.
# > This private key will be ignored.
# > bad permissions: ignore key: /path/to/wakame-vdc/tests/vdc.sh.d/pri.pem
# > Enter passphrase:
#
chmod 600 ${data_path}/pri.pem

cat <<CMDSET | grep -v '^#' | ./bin/vdc-manage -e
# Physical network definitions
network dc add public
network dc add-network-mode public securitygroup
network dc del-network-mode public passthru
# bridge only closed network
# network dc add vnet --allow-new-networks=true
network dc add vnet
network dc add-network-mode vnet l2overlay
network dc del-network-mode vnet passthru
network dc add management
network dc add-network-mode management securitygroup
network dc del-network-mode management passthru

# vlan
#vlan    add --tag-idb 1      --uuid vlan-demo1    --account-id ${account_id}
#network add           --uuid   nw-physical    --ipv4-gw ${ipv4_gw} --prefix ${prefix_len} --domain vdc.local --dns ${dns_server} --dhcp ${dhcp_server} --metadata ${metadata_server} --metadata-port ${metadata_port} --vlan-id 1 --description demo
# non vlan
network add \
 --uuid nw-physical \
 --ipv4-network ${ipv4_gw} \
 --ipv4_gw ${ipv4_gw} \
 --prefix ${prefix_len} \
 --domain vdc.local \
 --dns ${dns_server} \
 --dhcp ${dhcp_server} \
 --metadata ${metadata_server} \
 --metadata-port ${metadata_port} \
 --service-type std \
 --description "physical" \
 --display-name "physical" \
 --ip-assignment "asc"
network add \
 --uuid nw-vnet1 \
 --ipv4-network 10.1.1.0 \
 --prefix 24 \
 --domain vnet1.local \
 --service-type std \
 --description "virtual network 1" \
 --display-name "vnet1" \
 --ip-assignment "asc"
network add \
 --uuid nw-vnet2 \
 --ipv4-network 10.1.1.0 \
 --prefix 24 \
 --domain vnet2.local \
 --service-type std \
 --description "virtual network 2" \
 --display-name "vnet2" \
 --ip-assignment "asc"

# set forward interface(= physical network) from network
network forward nw-physical public
network forward nw-vnet1 vnet
network forward nw-vnet2 vnet

network dhcp addrange nw-physical $range_begin $range_end

resourcegroup map hng-shhost hn-${node_id}
resourcegroup map sng-shstor sn-${node_id}
resourcegroup map nwg-shnet  nw-physical

network reserve nw-physical --ipv4=${ipaddr}

spec  add --uuid is-demospec --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 1 --memory-size 256 --quota-weight 1
spec  add --uuid is-demo2    --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 2 --memory-size 256 --quota-weight 1
# BEGIN: Temporary add below two lines during instance spec migration.
spec  add --uuid is-small --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 1 --memory-size 256 --quota-weight 1
spec  add --uuid is-large --account-id ${account_id} --arch ${hva_arch} --hypervisor ${hypervisor} --cpu-cores 1 --memory-size 256 --quota-weight 2
# END: Temporary add below two lines during instance spec migration.
spec  addvif is-demo2 eth1
spec  addvif is-demo2 eth2

keypair add --account-id ${account_id} --uuid ssh-demo --private-key=$data_path/pri.pem --public-key=$data_path/pub.pem --description "'demo key1'" --service-type std --display-name "'demo'"

macrange add 525400 1 ffffff --uuid mr-demomacs

CMDSET

shlog ./bin/vdc-manage securitygroup add --uuid  sg-demofgr --account-id ${account_id} --description demo --service-type std --display-name demo
shlog ./bin/vdc-manage securitygroup modify sg-demofgr --rule=- <<EOF
# demo rule for demo instances
tcp:22,22,ip4:0.0.0.0
tcp:80,80,ip4:0.0.0.0
udp:53,53,ip4:0.0.0.0
icmp:-1,-1,ip4:0.0.0.0
EOF

cat <<EOS | mysql -uroot ${dcmgr_dbname}
INSERT INTO volume_snapshots values
 (1, '${account_id}', 'lucid1', 1, 'vol-lucid1', 1024, 0, 'available', 'local@local:none:${VDC_ROOT}/tmp/images/ubuntu-lucid-kvm-32.raw', NULL, now(), now(), 'std', 'lucid1'),
 (2, '${account_id}', 'lucid6', 1, 'vol-lucid6', 1024, 0, 'available', 'local@local:none:${VDC_ROOT}/tmp/images/ubuntu-lucid-kvm-ms-32.raw', NULL, now(), now(), 'std', 'lucid6');
EOS

# Install user/account definitions to the GUI database.
cd ${VDC_ROOT}/frontend/dcmgr_gui/

cat <<EOF | ./bin/gui-manage -e
account add --name="wakame" --uuid=a-00000000
user add --name="wakame" --uuid=u-00000000 --login_id=wakame --password=wakame --primary-account-id=a-00000000
user associate u-00000000 --account-ids "a-00000000"
account add --name="demo" --uuid=a-shpoolxx
user add --name="demo" --uuid=u-shpoolxx --login_id=demo --password=demo --primary-account-id=a-shpoolxx
user associate u-shpoolxx --account-ids "a-shpoolxx"
account quota set a-shpoolxx instance.count 10.0
account quota set a-shpoolxx instance.quota_weight 10.0
account quota set a-shpoolxx load_balancer.count 10.0

account add --name="demo1" --uuid=a-demo1
user add --name="demo1" --uuid=u-demo1 --login_id=demo1 --password=demo1 --primary-account-id=a-demo1 --locale="ja" --time-zone="Asia/Tokyo"
user associate u-demo1 --account-ids "a-demo1"
account quota set a-demo1 instance.count 10.0
account quota set a-demo1 instance.quota_weight 10.0
account quota set a-demo1 load_balancer.count 10.0
EOF

exit 0
