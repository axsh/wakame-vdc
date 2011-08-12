#!/usr/bin/env bash

mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

prefix_path=/usr/share/axsh/wakame-vdc

#Helper variable to determine network speed
speed=`sudo ethtool eth0 | grep Speed | cut -d ' ' -f2`

#Dialog default options
input_left=21
height=15
width=55
formheight=5

#Network options
ipaddr="${ipaddr:-$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $7}')}"
network_speed=${speed:0:$((${#speed}-4))}
network_gateway="${network_gateway:-$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $3}')}"
network_mask=`ifconfig | grep ${ipaddr} | tr -s ' ' | cut -d ' ' -f5 | cut -d ':' -f2`
network_prefix=$(mask2cidr ${network_mask})
nat_address=
nat_prefix=
metadata_port=9002
hostname=vdc.local

#Dialog boxes
#dialog --nocancel --backtitle "Wakame-vdc configuration" \
 #--title "Network Configuration" \
 #--form "\nPlease enter the network configuration for Wakame-vdc:" $height $width $formheight \
 #"Domain name:" 1 1 "$hostname" 1 $input_left $(($width-2)) 255 \
 #"Default gateway:" 2 1 "$network_gateway" 2 $input_left 16 15 \
 #"Prefix:" 3 1 "$network_prefix" 3 $input_left 3 2 \
 #"Bandwidth (Mbit/s):" 4 1 "$network_speed" 4 $input_left 7 6 \
 #2> ${prefix_path}/wakame_network.out
 
#dialog --nocancel --backtitle "Wakame-vdc configuration" \
  #--title "Outside Network Configuration" \
  #--form "\nPlease enter the outside network configuration for Wakame-vdc:\n (Leave blank for none)" $height $width 3 \
  #"Default gateway:" 1 1 "$nat_address" 1 $input_left 16 15 \
  #"Prefix:" 2 1 "$nat_prefix" 2 $input_left 3 2 \
  #2> ${prefix_path}/wakame_nat.out
#clear

echo vdc.local >> ${prefix_path}/wakame_network.out
echo ${network_gateway} >> ${prefix_path}/wakame_network.out
echo ${network_prefix} >> ${prefix_path}/wakame_network.out
echo 100 >> ${prefix_path}/wakame_network.out

echo "" >> ${prefix_path}/wakame_nat.out
echo "" >> ${prefix_path}/wakame_nat.out

#Store network data in arrays
for line in $(<${prefix_path}/wakame_network.out); do
  network[$index]="$line"
  index=$(($index+1))
done

index=0
for line in $(<${prefix_path}/wakame_nat.out); do
  nat[$index]="$line"
  index=$(($index+1))
done

cd ${prefix_path}/dcmgr/bin

if [ -n "${ipaddr}" ]; then
  network_uuid=`./vdc-manage network add -u nw-demonet --ipv4_gw ${network[1]} --prefix ${network[2]} --domain ${network[0]} --dns ${ipaddr} --dhcp ${ipaddr} --metadata ${ipaddr} --metadata_port ${metadata_port} -b ${network[3]}`
  #Workaround for an nsa bug that breaks DHCP on first run
  #The bug occurs when /var/tmp/dnsmasq-dhcp.conf doesn't exist yet
  netmask=`${prefix_path}/cidr2mask.sh ${network_prefix}`
  echo "server=8.8.8.8
log-facility=/var/log/dnsmasq.log
#log-queries
log-dhcp
dhcp-range=net:nw-demonet,${network[1]},static,${netmask}
dhcp-option=nw-demonet,option:netmask,${netmask}
dhcp-option=nw-demonet,option:router,${network_gateway}
dhcp-option=nw-demonet,option:dns-server,${ipaddr}
dhcp-option=nw-demonet,option:domain-name,${network[0]}
#dhcp-option=nw-demonet,option:domain-search,${network[0]}
" > /var/tmp/dnsmasq-dhcp.conf
fi

if [ -n "${nat[0]}" ] && [ -n "${nat[1]}" ]; then
  nat_uuid=`./vdc-manage network add --ipv4_gw ${nat[0]} --prefix ${nat[1]}`
  ./vdc-manage network nat $network_uuid -o $nat_uuid
fi

#Clean up temporary files
#rm -f ${prefix_path}/wakame_network.out
#rm -f ${prefix_path}tmp/wakame_nat.out
