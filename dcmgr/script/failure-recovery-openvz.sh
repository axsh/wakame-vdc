#!/bin/bash

# Determine Wakame root directory. This script needs to reside in $dcmgr_root/script
dcmgr_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Determine where hva.conf is
if [ -z "$HVA_CONF" ]; then
  if [ -f /etc/wakame-vdc/hva.conf ]; then
    HVA_CONF=/etc/wakame-vdc/hva.conf
  else
    HVA_CONF=$dcmgr_root/config/hva.conf
  fi
fi

if [ ! -f $HVA_CONF ]; then
  echo "Couldn't find hva.conf file. Please place it in either /etc/wakame-vdc/ or in $dcmgr_root/config/"
  exit 1
fi
echo "using config file: ${HVA_CONF}"

# Determine Wakame's instances tmp directory
instances_tmp_dir=`grep vm_data_dir $HVA_CONF | sed "s/.*'\(.*\)'[^']*$/\1/"`
echo $instances_tmp_dir | grep -q vm_data_dir
if [ $? == 0 ]; then instances_tmp_dir=`grep vm_data_dir $HVA_CONF | sed 's/.*"\(.*\)"[^"]*$/\1/'`; fi

# If we are using openvswitch, we will need to remove the instances' vnics from the switch
lsmod | grep -q openvswitch_mod
if [ "$?" == "0" ]; then
  # This one-liner gets us a nice list of the interfaces that are currently on Open vSwitch. There is probably a shorter cleaner way to write it but it works. :P
  vifs=`ovs-vsctl show | grep Interface | tr -s " " | cut -d " " -f3 | sed 's/.*"\(.*\)"[^"]*$/\1/'`

  for vif_name in $vifs; do
    # And this one-liner gives us a nice list of interfaces that exist on the system while omitting "lo"
    ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | grep -q ${vif_name}
    if [ $? != '0' ]; then
      # We delete every interface on Open vSwitch that doesn't show up in ifconfig -a.
      # If we don't do this, Openvz will complain that it can't add its vnics to the bridge.
      ovs-vsctl del-port ${vif_name}
    fi
  done
fi

# Finally we bring up all of this HVA's instances that have 'running' in their state file
for dirname in `ls ${instances_tmp_dir}`; do
  if [[ $dirname == i-* ]] && [[ `cat ${instances_tmp_dir}/${dirname}/state` == "running" ]]; then
    # Check if this instance is already running
    vzlist | grep $dirname | grep -q running
    if [ "$?" != "0" ]; then
      # Check if this is a tar.gz based instance and mount its root partition if it's not
      file ${instances_tmp_dir}/${dirname}/${dirname} | grep -q "POSIX tar archive (GNU)"
      if [ "$?" != "0" ]; then
        # Create loop devices for the partitions in the image
        kpartx -va $instances_tmp_dir/$dirname/$dirname | cut -d " " -f3 | while read line; do
          # Determine which of these loop devices is the root partition
          root_device="/dev/mapper/$line"
          device_uuid=`blkid $root_device | cut -d '"' -f2`
          search_uuid=`cat $instances_tmp_dir/$dirname/root_partition | cut -d "=" -f2`

          if [ "$device_uuid" == "$search_uuid" ]; then
            # We found the root partition. Now mount it.
            cid=`cat $instances_tmp_dir/$dirname/openvz.ctid`
            mount $root_device /vz/private/${cid}
            break
          fi
        done
      fi

      # Mount the metadata drive images and make sure their correct loop devices
      # are stored in Wakame's temp directory
      loop_device=`kpartx -va $instances_tmp_dir/$dirname/metadata.img | cut -d " " -f3`
      mount /dev/mapper/${loop_device} ${instances_tmp_dir}/${dirname}/metadata

      # Start the instance
      vzctl start ${dirname}
    fi
  fi
done
