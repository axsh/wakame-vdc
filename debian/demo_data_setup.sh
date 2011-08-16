#!/usr/bin/env bash

prefix_path=/usr/share/axsh/wakame-vdc

ng_rules=( \
"tcp:22,22,ip4:0.0.0.0" \
"tcp:80,80,ip4:0.0.0.0" \
"udp:53,53,ip4:0.0.0.0" \
"icmp:-1,-1,ip4:0.0.0.0" \
)
account_id="a-shpoolxx"
hypervisor="kvm"

local_store_path=${prefix_path}/images
remote_store_path=http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage
vmimage_files=( ubuntu10.04_amd64.raw debian6.0_amd64.raw )
image_arch=x86_64

#Start data entry
cd ${prefix_path}/dcmgr/bin

echo "vdc-manage group add -a ${account_id} -n default -d demo"
ng_uuid=`./vdc-manage group add -a ${account_id} -n default -d demo`

for rule in ${ng_rules[*]}; do
  echo "vdc-manage group addrule $ng_uuid -r $rule"
  ./vdc-manage group addrule $ng_uuid -r $rule
done

echo "vdc-manage host add hva.demo1 -u hp-demohost -f -a ${account_id} -c 100 -m 400000 -p ${hypervisor} -r $(uname -m)"
./vdc-manage host add hva.demo1 -u hp-demohost -f -a ${account_id} -c 100 -m 400000 -p ${hypervisor} -r $(uname -m) > /dev/null

#TODO: get proper uuid in here
echo "vdc-manage tag map tag-shhost -o hp-demohost"
./vdc-manage tag map tag-shhost -o hp-demohost
echo "vdc-manage tag map tag-shnet  -o nw-demonet"
./vdc-manage tag map tag-shnet  -o nw-demonet

echo "vdc-manage spec  add -u is-demospec -a ${account_id} -r $(uname -m) -p ${hypervisor} -c 1 -m 256 -w 1"
./vdc-manage spec  add -u is-demospec -a ${account_id} -r $(uname -m) -p ${hypervisor} -c 1 -m 256 -w 1 #> /dev/null

#attempt to download image
mkdir -p ${local_store_path}
#TODO: Add option to skip image download
for vmimage_file in ${vmimage_files[@]}; do
  if [ ! -f ${local_store_path}/${vmimage_file} ]; then
    cd ${local_store_path}
    wget ${remote_store_path}/${vmimage_file}.gz
    if [ ! "$?" -ne "0" ]; then
      echo "Unpacking image..."
      gunzip ${vmimage_file}.gz
      cd ${prefix_path}/dcmgr/bin
      echo "vdc-manage image add local ${local_store_path}/${vmimage_file} -a ${account_id} -r ${image_arch} -s init"
      ./vdc-manage image add local ${local_store_path}/${vmimage_file} -a ${account_id} -r ${image_arch} -s init
    fi
  else
    cd ${prefix_path}/dcmgr/bin
    echo "vdc-manage image add local ${local_store_path}/${vmimage_file} -a ${account_id} -r ${image_arch} -s init"
    ./vdc-manage image add local ${local_store_path}/${vmimage_file} -a ${account_id} -r ${image_arch} -s init
  fi
done

exit 0
