#!/usr/bin/env bash

directory=/etc/network/
filename=interfaces
original_filename=interfaces

#Make a backup copy of the original file name
cd ${directory}
cp ${original_filename} ${original_filename}.`date +%Y%m%d-%H%M%S`

prim_interface=`grep "# The primary network interface" -A 1 ${original_filename} | tail -n 1 | cut -d ' ' -f2`
bridge_interface="br0"

#Check if we're using dhcp
dhcp=`grep "# The primary network interface" -A 2 ${original_filename} | tail -n 1 | grep dhcp`
nw_up=`grep "# The primary network interface" -A 2 ${original_filename}`
if [ -z "$nw_up" ]; then
  echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The bridge
auto ${bridge_interface}
iface ${bridge_interface} inet static
	bridge_stp off
	bridge_fd 0
	bridge_maxwait 1" > ${directory}/${filename}
elif [ ! -z "$dhcp" ]; then
  #Set up the bridge with dhcp
  echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ${prim_interface}
iface ${prim_interface} inet manual
	up /sbin/ifconfig ${prim_interface} promisc

# The bridge
auto ${bridge_interface}
iface ${bridge_interface} inet dhcp
	bridge_ports ${prim_interface}
	bridge_stp off
	bridge_fd 0
	bridge_maxwait 1
" > ${directory}/${filename}
else
  #Set up the bridge with a static ip
  address=`grep "address" ${original_filename}`
  netmask=`grep "netmask" ${original_filename}`
  gateway=`grep "gateway" ${original_filename}`
  nameservers=`grep "dns-nameservers" ${original_filename}`
  network_address=`grep "network" ${original_filename} | grep -v interface`
  broadcast_address=`grep "broadcast" ${original_filename}`

  cd $directory
  echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ${prim_interface}
iface ${prim_interface} inet manual
	up /sbin/ifconfig ${prim_interface} promisc

# The bridge
auto ${bridge_interface}
iface ${bridge_interface} inet static
${address}
${netmask}
${network_address}
${broadcast_address}
${gateway}
${nameservers}
	bridge_ports ${prim_interface}
	bridge_stp off
	bridge_fd 0
	bridge_maxwait 1
" > ${directory}/${filename}
fi
