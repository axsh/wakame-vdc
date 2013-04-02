#!/bin/bash

set -e

vdc_data=${vdc_data:?"vdc_data needs to be set"}
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
  [ -n "${gw_dev}" ]      || gw_dev=$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $5}')
  [ -n "${ipaddr}" ]      || ipaddr=$(/sbin/ip addr show ${gw_dev} | grep -w inet | awk '{print $2}')
  [ -n "${range_begin}" ] || range_begin=`ipcalc -n ${ipaddr}/${prefix_len} | sed 's,.*=,,'`
  [ -n "${range_end}"   ] || range_end=`ipcalc -b ${ipaddr}/${prefix_len} | sed 's,.*=,,'`
} || {
  # ubuntu
  [ -n "${range_begin}" ] || range_begin=`ipcalc ${ipv4_gw}/${prefix_len} | awk '$1 == "HostMin:" { print $2 }'`
  [ -n "${range_end}"   ] || range_end=`ipcalc ${ipv4_gw}/${prefix_len} | awk '$1 == "HostMax:" { print $2 }'`
}

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
network dc add null1
network dc add-network-mode null1 l2overlay
network dc add null2
network dc add-network-mode null2 l2overlay
network dc add management
network dc add-network-mode management securitygroup
network dc del-network-mode management passthru

# vlan
#vlan    add --tag-idb 1      --uuid vlan-demo1    --account-id ${account_id}
#network add           --uuid   nw-demo1    --ipv4-gw ${ipv4_gw} --prefix ${prefix_len} --domain vdc.local --dns ${dns_server} --dhcp ${dhcp_server} --metadata ${metadata_server} --metadata-port ${metadata_port} --vlan-id 1 --description demo
# non vlan
network add \
 --uuid nw-demo1 \
 --ipv4-network ${ipv4_gw} \
 --ipv4_gw ${ipv4_gw} \
 --prefix ${prefix_len} \
 --domain vdc.local \
 --dns ${dns_server} \
 --dhcp ${dhcp_server} \
 --metadata ${metadata_server} \
 --metadata-port ${metadata_port} \
 --service-type std \
 --description "demo" \
 --display-name "demo1" \
 --ip-assignment "asc"
network add \
 --uuid nw-demo2 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10 --service-type std --display-name "'demo2'" --ip-assignment "asc"
network add \
 --uuid nw-demo3 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10 --service-type std --display-name "'demo3'" --ip-assignment "asc"
network add \
 --uuid nw-demo4 --ipv4-network 10.100.0.0 --prefix 24 --domain vdc.local --metric 10 --service-type std --display-name "'demo4'" --ip-assignment "asc"
network add \
 --uuid nw-demo5 --ipv4-network 10.101.0.0 --prefix 24 --domain vdc.local --metric 10 --service-type std --display-name "'demo5'" --ip-assignment "asc"
network add \
 --uuid nw-demo6 \
 --network-mode l2overlay \
 --ipv4-network 10.102.0.0 \
 --ipv4_gw 10.102.0.1 \
 --prefix 24 \
 --domain vnet6.local \
 --metric 10 \
 --service-type std \
 --display-name "demo6" \
 --ip-assignment "asc"
network add \
 --uuid nw-demo7 \
 --network-mode l2overlay \
 --ipv4-network 10.103.0.0 \
 --ipv4_gw 10.103.0.1 \
 --prefix 24 \
 --domain vnet7.local \
 --metric 10 \
 --service-type std \
 --display-name "demo7" \
 --ip-assignment "asc"
network add \
 --uuid nw-demo8 \
 --ipv4-network 10.1.0.0 \
 --ipv4_gw 10.1.0.1 \
 --prefix 24 \
 --domain vnet8.local \
 --metric 10 \
 --service-type lb \
 --display-name "demo8" \
 --ip-assignment "asc"

# set forward interface(= physical network) from network
network forward nw-demo1 public
network forward nw-demo2 public
network forward nw-demo3 public
network forward nw-demo4 null1
network forward nw-demo5 null2
network forward nw-demo6 null1
network forward nw-demo7 null1
network forward nw-demo8 management

network service external-ip nw-demo1
network service dhcp nw-demo6 --ipv4=10.102.0.2
network service dhcp nw-demo7 --ipv4=10.103.0.2
network service dns nw-demo7 --ipv4=10.103.0.2

network dhcp addrange nw-demo1 $range_begin $range_end
network dhcp addrange nw-demo2 10.100.0.61 10.100.0.65
network dhcp addrange nw-demo2 10.100.0.70 10.100.0.75
# range prepend
network dhcp addrange nw-demo2 10.100.0.68 10.100.0.75
# range append
network dhcp addrange nw-demo2 10.100.0.72 10.100.0.80
# range merge
network dhcp addrange nw-demo2 10.100.0.60 10.100.0.80
network dhcp addrange nw-demo3 10.101.0.60 10.101.0.80
network dhcp addrange nw-demo4 10.100.0.100 10.100.0.130
network dhcp addrange nw-demo5 10.101.0.100 10.101.0.130
network dhcp addrange nw-demo6 10.102.0.10 10.102.0.240
network dhcp addrange nw-demo7 10.103.0.10 10.103.0.240
network dhcp addrange nw-demo8 10.1.0.10 10.1.0.240

network pool add --uuid="external" --display-name="external ips" --expire-initial=600 --expire-released=120
network pool add-dcn ipp-external public

resourcegroup map hng-shhost hn-${node_id}
resourcegroup map sng-shstor sn-${node_id}
resourcegroup map nwg-shnet  nw-demo1

network reserve nw-demo1 --ipv4=${ipaddr}

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
 (1, '${account_id}', 'lucid1', 1, 'vol-lucid1', 1024, 0, 'available', 'local@local:none:${vdc_data}/images/ubuntu-lucid-kvm-32.raw', NULL, now(), now(), 'std', 'lucid1'),
 (2, '${account_id}', 'lucid6', 1, 'vol-lucid6', 1024, 0, 'available', 'local@local:none:${vdc_data}/images/ubuntu-lucid-kvm-ms-32.raw', NULL, now(), now(), 'std', 'lucid6');
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
