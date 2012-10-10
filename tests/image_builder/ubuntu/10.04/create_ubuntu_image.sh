#!/usr/bin/env bash
#rootsize=10240
rootsize=256
swapsize=128
init_script_location=$PWD/wakame-init
dns_server=8.8.8.8

metadata_type=$1

#Function to generate the mount directory later on
function randdir
{
echo `</dev/urandom tr -dc A-Za-z0-9 | head -c8`
}

#Make sure we're running as root
if [ "$(id -u)" != "0" ]; then
   echo "Error: This script must be run as root"
   exit 1
fi

#Make sure ubuntu vm builder is installed
echo "Checking if ubuntu-vm-builder is installed"
builderinstalled=`aptitude search '~i ^ubuntu-vm-builder'`
if [ -z "$builderinstalled" ]; then
  echo "Ubuntu-vm-builder not found ... Installing"
  apt-get install -y ubuntu-vm-builder
else
  echo "Ubuntu-vm-builder found"
fi

#Check if ubuntu-kvm folder exists
if [ -d ./ubuntu-kvm ]; then
  echo "Error: ubuntu-kvm folder already exists"
  exit 1
fi

#Check if there is a startup script
if [ ! -f $init_script_location ]; then
  echo "Error: startup script not found at: " $init_script_location
  exit 1
fi

#Create the ubuntu image
echo "Creating VM image"
ubuntu-vm-builder kvm lucid --mirror=http://jp.archive.ubuntu.com/ubuntu --rootsize $rootsize --swapsize $swapsize --addpkg ssh --addpkg curl --dns $dns_server $@

#Determine the filename from the run script
qcow_filename=`grep exec ubuntu-kvm/run.sh | cut -d ' ' -f8 | cut -d = -f2`

#Convert it to raw
echo "Converting qcow image to raw"
raw_filename=`rename -n 's/\.qcow2$/.raw/' $qcow_filename  | cut -d ' ' -f4`
qemu-img convert -f qcow2 -O raw ubuntu-kvm/$qcow_filename $raw_filename

#Generate the image dir
tmp_mount_dir="/mnt/"$(randdir)
while [ -d ./test ] || [ -f ./test ]; do
  tmp_mount_dir="/mnt/"$(randdir)
done

#Mount the image
loop_image=`kpartx -va $raw_filename | cut -d ' ' -f3 | head -n 1`
echo "Creating temporary directory "$tmp_mount_dir
mkdir $tmp_mount_dir
echo "Mounting image"
mount /dev/mapper/$loop_image $tmp_mount_dir

#Set the dns server
echo "nameserver 8.8.8.8" > $tmp_mount_dir/etc/resolv.conf

#Handle mac address
echo "Unsetting mac address"
rm -f $tmp_mount_dir/etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null $tmp_mount_dir/etc/udev/rules.d/70-persistent-net.rules
#sed -i 's/HWADDR=.*/#HWADDR=xx:xx:xx:xx:xx:xx/' $tmp_mount_dir/etc/sysconfig/network-scripts/ifcfg-eth0

#Remove SSH host keys
echo "Removing ssh host keys"
rm -f $tmp_mount_dir/etc/ssh/ssh_host*

#Set up the startup script
echo "Setting up the startup script"
cp $init_script_location $tmp_mount_dir/etc/wakame_init
chmod +x $tmp_mount_dir/etc/wakame_init
sed -i '/exit 0/d' $tmp_mount_dir/etc/rc.local
echo "/etc/wakame_init ${metadata_type}" >> $tmp_mount_dir/etc/rc.local
echo "exit 0" >> $tmp_mount_dir/etc/rc.local

#Load acpiphp.ko at boot
echo "Adding acpiphp to kernel modules to load at boot"
echo acpiphp >> $tmp_mount_dir/etc/modules


#Clean up log files
echo "Cleaning log files"
rm $tmp_mount_dir/var/log/*.gz
find $tmp_mount_dir/var/log/ -type f | while read line; do : > $line; done

#Unmount the image and remove the temporary directory
echo "Unmounting image"
umount $tmp_mount_dir
#Remove temporary directories
echo "Deleting temporary directory"
rmdir $tmp_mount_dir
rm -r ubuntu-kvm
#Remove loop device
echo "Removing loop device"
kpartx -vd $raw_filename
echo "Done. Image file: " $raw_filename

