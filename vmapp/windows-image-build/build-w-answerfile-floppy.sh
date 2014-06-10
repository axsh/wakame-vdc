#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

try()
{
    eval "$@" || reportfail "$@"
}

set -e
set -x

case "$1" in
    *8*)
	WINIMG=win-2008.raw
	ANSFILE=Autounattend-08.xml
	WINISO=SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_Japanese_w_SP1_MLF_X17-22600.ISO
	UD=8 # unique digit
	;;
    *12*)
	WINIMG=win-2012.raw
	ANSFILE=Autounattend-12.xml
	WINISO=SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_Japanese_-3_MLF_X19-53644.ISO
	UD=9 # unique digit
	;;
    *)
	reportfail "First parameter should be 2008 or 2012"
	;;
esac

# Decide on ports for KVM's user-mode networking port forwarding
RDP=1${UD}389
SSH=1${UD}022
MISC=1${UD}123
VNC=1${UD}0
echo "vncviewer :$(( VNC + 5900 ))"

portforward=""
portforward="$portforward,hostfwd=tcp:0.0.0.0:$RDP-:3389"  # RDP
portforward="$portforward,hostfwd=tcp:0.0.0.0:$SSH-:22"  # ssh (for testing)
portforward="$portforward,hostfwd=tcp:0.0.0.0:$MISC-:7890"  # test (for testing)

# Special case for testing already built image
if [[ "$2" == -test* ]]
then
    setsid >>./kvm.stdout 2>>./kvm.stderr \
	   kvm -m 2000 -smp 1 \
	   -no-kvm-pit-reinjection \
	   -vnc :$VNC \
	   -drive file="$WINIMG",id=windows2012-GEN-drive,cache=none,aio=native,if=none \
	   -device virtio-blk-pci,id=windows2012-GEN,drive=windows2012-GEN-drive,bootindex=0,bus=pci.0,addr=0x4 \
	   -drive file="$SCRIPT_DIR/metadata.img",id=metadata-drive,cache=none,aio=native,if=none \
	   -device virtio-blk-pci,id=metadata,drive=metadata-drive,bus=pci.0,addr=0x5 \
	   -net nic,vlan=0,model=virtio,macaddr=52-54-00-11-a0-5b \
	   -net user,vlan=0${portforward} \
	   -usbdevice tablet  \
	   -k ja &
    exit
fi

# Copy Autounattend.xml into fresh floppy image
FLP="./answerfile-floppy.img"
dd if=/dev/zero of="$FLP" bs=1k count=1440
mkfs.vfat "$FLP"
mkdir -p "./mnt"
sudo mount -t vfat -o loop $FLP "./mnt"
sudo cp "$SCRIPT_DIR/$ANSFILE" "./mnt/Autounattend.xml"
for fn in FinalStepsForInstall.cmd \
	     Unattend-for-first-boot.xml \
	     wakame-init-first-boot.ps1 \
	     SetupComplete-firstboot.cmd \
	     SetupComplete-install.cmd \
	     run-sysprep.cmd \
	     wakame-init-every-boot.ps1 ; do
    sudo cp "$SCRIPT_DIR/$fn" "./mnt/"
done

sudo umount "./mnt"

# Create 30GB image
rm -f "$WINIMG"
qemu-img create -f raw "$WINIMG" 30G

setsid >>./kvm.stdout 2>>./kvm.stderr \
       kvm -m 2000 -smp 1 \
       -fda "$FLP" \
       -drive file="$SCRIPT_DIR/$WINISO",index=2,media=cdrom \
       -drive file="$SCRIPT_DIR/virtio-win-0.1-74.iso",index=3,media=cdrom \
       -boot d \
       -no-kvm-pit-reinjection \
       -vnc :$VNC \
       -drive file="$WINIMG",id=windows2012-GEN-drive,cache=none,aio=native,if=none \
       -device virtio-blk-pci,id=windows2012-GEN,drive=windows2012-GEN-drive,bootindex=0,bus=pci.0,addr=0x4 \
       -net nic,vlan=0,model=virtio,macaddr=52-54-00-11-a0-5b \
       -net user,vlan=0${portforward} \
       -usbdevice tablet  \
       -k ja &
