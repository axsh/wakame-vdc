#!/bin/bash

# Determine Wakame root directory. This script needs to reside in $wakame_root/scripts
wakame_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Determine Wakame's instances tmp directory
instances_tmp_dir=`grep vm_data_dir $wakame_root/dcmgr/config/hva.conf | sed "s/.*'\(.*\)'[^']*$/\1/"`
echo $instances_tmp_dir | grep -q vm_data_dir
if [ $? == 0 ]; then instances_tmp_dir=`grep vm_data_dir $wakame_root/dcmgr/config/hva.conf | sed 's/.*"\(.*\)"[^"]*$/\1/'`; fi

# This one-liner gets us a nice list of the interfaces that are currently on Open vSwitch. There is probably a shorter cleaner way to write it but it works. :P
for vif_name in `ovs-vsctl show | grep Interface | tr -s " " | cut -d " " -f3 | sed 's/.*"\(.*\)"[^"]*$/\1/'`; do
  ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | grep -q ${vif_name}
  if [ $? != '0' ]; then
    #echo "deleting vif ${vif_name} from Open vSwitch"
    ovs-vsctl del-port ${vif_name}
  fi
done

for dirname in `ls ${instances_tmp_dir}`; do
  if [[ $dirname == i-* ]]; then
    #echo "mounting metadata for ${dirname}"
    #echo "loop_device = `kpartx -va $instances_tmp_dir/$dirname/metadata.img | cut -d \" \" -f3`"
    loop_device=`kpartx -va $instances_tmp_dir/$dirname/metadata.img | cut -d " " -f3`
    mount -o loop /dev/mapper/${loop_device} ${instances_tmp_dir}/${dirname}/metadata
    echo "/dev/mapper/${loop_device}" > ${instances_tmp_dir}/${dirname}/metadata.lodev

    vzctl start ${dirname}
  #else
    #echo "Doing nothing for ${dirname}"
  fi
done
