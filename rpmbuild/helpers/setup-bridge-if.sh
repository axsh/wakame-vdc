#!/bin/bash
#
# OPTIONS
#
#  --brname=br0
#  --ifname=eth0
#
#  --ip=192.0.2.10
#  --mask=255.255.255.0
#  --net=192.0.2.0
#  --bcast=192.0.2.255
#  --gw=192.0.2.1
#
set -e
#set -x

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      args="${args} ${arg}"
      ;;
  esac
  shift
done

#
brname=${brname:-br0}
ifname=${ifname:-}

ip=${ip}
mask=${mask:-}
net=${net:-}
bcast=${bcast:-}
gw=${gw:-}

ifcfg_prefix=/etc/sysconfig/network-scripts/ifcfg



#
# ifcfg-brX
#
[ -z "${ip}" ] && {
  BOOTPROTO=dhcp
} || {
  BOOTPROTO=static
}

cat <<EOS > ${ifcfg_prefix}-${brname}
DEVICE=${brname}
TYPE=Bridge
ONBOOT=yes

BOOTPROTO=${BOOTPROTO}
$([ -z "${ip}"    ] || echo "IPADDR=${ip}")
$([ -z "${net}"   ] || echo "NETMASK=${net}")
$([ -z "${bcast}" ] || echo "BROADCAST=${bcast}")
$([ -z "${gw}"    ] || echo "GATEWAY=${gw}")
EOS
echo ">>> ${ifcfg_prefix}-${brname}"
cat ${ifcfg_prefix}-${brname}

#
# ifcfg-ethX
#
[ -z ${ifname} ] || {
  cat <<EOS > ${ifcfg_prefix}-${ifname}
DEVICE=${ifname}
ONBOOT=yes
BOOTPROTO=static

BRIDGE=${brname}
TYPE=Ethernet
EOS
  echo ">>> ${ifcfg_prefix}-${ifname}"
  cat ${ifcfg_prefix}-${ifname}
}
