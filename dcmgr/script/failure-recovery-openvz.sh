#!/bin/bash

# Determine Wakame root directory. This script needs to reside in $dcmgr_root/script
dcmgr_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Determine Wakame's instances tmp directory
instances_tmp_dir=`grep vm_data_dir $dcmgr_root/config/hva.conf | sed "s/.*'\(.*\)'[^']*$/\1/"`
echo $instances_tmp_dir | grep -q vm_data_dir
if [ $? == 0 ]; then instances_tmp_dir=`grep vm_data_dir $dcmgr_root/config/hva.conf | sed 's/.*"\(.*\)"[^"]*$/\1/'`; fi

# This one-liner gets us a nice list of the interfaces that are currently on Open vSwitch. There is probably a shorter cleaner way to write it but it works. :P
for vif_name in `ovs-vsctl show | grep Interface | tr -s " " | cut -d " " -f3 | sed 's/.*"\(.*\)"[^"]*$/\1/'`; do
  # And this one-liner gives us a nice list of interfaces that exist on the system while omitting "lo"
  ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | grep -q ${vif_name}
  if [ $? != '0' ]; then
    # We delete every interface on Open vSwitch that doesn't show up in ifconfig -a.
    # If we don't do this, Openvz will complain that it can't add its vnics to the bridge.
    ovs-vsctl del-port ${vif_name}
  fi
done

# Finally we bring up all of this HVA's instances that have 'running' in their state file
for dirname in `ls ${instances_tmp_dir}`; do
  if [[ $dirname == i-* ]] && [[ `cat ${instances_tmp_dir}/${dirname}/state` == "running" ]]; then
    # Mount the metadata drive images and make sure their correct loop devices
    # are stored in Wakame's temp directory
    loop_device=`kpartx -va $instances_tmp_dir/$dirname/metadata.img | cut -d " " -f3`
    mount -o loop /dev/mapper/${loop_device} ${instances_tmp_dir}/${dirname}/metadata
    echo "/dev/mapper/${loop_device}" > ${instances_tmp_dir}/${dirname}/metadata.lodev

    # Start the instance
    vzctl start ${dirname}
  fi
done
