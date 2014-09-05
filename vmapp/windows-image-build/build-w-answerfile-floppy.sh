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

usage() {
    cat <<'EOF'

A quick guide for using this script to make Windows images is in
README.md.  This script also has other features for experimenting with
Windows images.  In order to use these, it is probably necessary read
through it to understand the script and its limitations.  However, for
quick hints, the intended use is as follows:

1) Follow instruction in README.md
2) keep calling $SDIR/build-w-answerfile-floppy.sh 2008 -next

This will cycle the window image through first boot, second boot,
shutdown, reboot, sysprep, shutdown, and then start again with first
boot, etc.  At various points, the script will output Windows log
files and network packet dumps to a directory named run-{2008,2012}-*.
The first set of log files have "gen0" in the log file names.  After
the next first boot, "gen1" becomes part of the log file names, etc.,
so that each cycle from first-boot to sysprep gets uniquely named
files.  It is easer to make sense of all the log files if the
directory is sorted by date.

Note the following environment are used:
BOOTDATE (defaults to 2014-04-01)
MACADDR (defaults to 52-54-00-11-a0-5b)
FIRSTBOOT (defaults to "", i.e. do not put in meta-data/first-boot)
AUTOACTIVATE (defaults to "", i.e. do not put in meta-data/auto-activate)
NATNET (defaults to "", i.e. disconnect from Internet)
PROXY (defaults to "", i.e. do not put in meta-data/auto-activate-proxy)
IPV4 (defaults to 10.0.2.15)
NETMASK (defaults to 255.255.255.0)
GATEWAY (defaults to 10.0.2.2)
EOF
    exit
}

if [ "$BOOTDATE" == "" ] ; then
    # By default, set the date to something later than the files in
    # the Windows Server 2012 ISO.  All the files in the ISO seem to
    # be dated 2014-03-18.  Setting after this but earlier than
    # today's date makes it possible to do experiments with KVM faking
    # dates but still be using dates that would be plausible to
    # Windows and Microsoft's activaion server.
    BOOTDATE="2014-04-01"
fi

boot-date-param()
{
    [ "$BOOTDATE" != "now" ] && echo "-rtc base=$BOOTDATE"
}

boot-common-params()
{
    echo -m 2000 -smp 1 \
	 -no-kvm-pit-reinjection \
	 -vnc :$VNC \
	 -drive file="$WINIMG",id=windows-drive,cache=none,aio=native,if=none \
	 -device virtio-blk-pci,drive=windows-drive,bootindex=0,bus=pci.0,addr=0x4 \
	 -usbdevice tablet  \
	 -k ja $(boot-date-param)
}

[ "$MACADDR" == "" ] &&  MACADDR="52-54-00-11-a0-5b"
[ "$IPV4" == "" ] &&  IPV4="10.0.2.15"
[ "$NETMASK" == "" ] &&  NETMASK="255.255.255.0"
[ "$GATEWAY" == "" ] &&  GATEWAY="10.0.2.2"


configure-metadata-disk()
{
    [ -f metadata.img ] || reportfail "metadata.img file not found in current directory"
    mount-image "$(pwd)" metadata.img 1 || reportfail "mounting of metadata.img failed"
    sudo bash -c 'echo "DEMO1-VM" >mntpoint/meta-data/local-hostname'
    
    # networking interfaces
    sudo bash -c "mkdir mntpoint/meta-data/network/interfaces/macs/$MACADDR"
    sudo bash -c "echo $IPV4 >mntpoint/meta-data/network/interfaces/macs/$MACADDR/local-ipv4s"
    sudo bash -c "echo $NETMASK >mntpoint/meta-data/network/interfaces/macs/$MACADDR/x-netmask"
    sudo bash -c "echo $GATEWAY >mntpoint/meta-data/network/interfaces/macs/$MACADDR/x-gateway"
    sudo bash -c "echo 8.8.8.8 >mntpoint/meta-data/network/interfaces/macs/$MACADDR/x-dns"
    
    # hosts file
    sudo bash -c 'mkdir mntpoint/meta-data/extra-hosts'
    sudo bash -c 'echo 192.168.2.22 >mntpoint/meta-data/extra-hosts/twotwo'
    sudo bash -c 'echo 192.168.2.23 >mntpoint/meta-data/extra-hosts/twothree'

    # defaults values for zabbix testing
    sudo bash -c "echo $IPV4 >mntpoint/meta-data/local-ipv4"
    sudo bash -c 'echo "DEMO1-VM" >mntpoint/meta-data/instance-id'
    sudo bash -c 'echo "192.168.2.1" >mntpoint/meta-data/x-monitoring/zabbix-servers'
    
    if [ "$FIRSTBOOT" = "" ]; then
	sudo rm -f mntpoint/meta-data/first-boot
    else
	sudo touch mntpoint/meta-data/first-boot
	sudo touch "thisrun/first-boot-set-$(date +%y%m%d-%H%M%S)"
    fi

    if [ "$AUTOACTIVATE" = "" ]; then
	sudo rm -f mntpoint/meta-data/auto-activate
    else
	sudo touch mntpoint/meta-data/auto-activate
	sudo touch "thisrun/auto-activate-set-$(date +%y%m%d-%H%M%S)"
    fi

    if [ "$PROXY" = "" ]; then
	sudo rm -f mntpoint/meta-data/auto-activate-proxy
    else
	echo "$PROXY" | sudo tee mntpoint/meta-data/auto-activate-proxy
	sudo touch "thisrun/auto-activate-proxy-set-$(date +%y%m%d-%H%M%S)"
    fi
    umount-image
}

boot-and-log-kvm-boot()
{
    echo "$@" >"thisrun/kvm-boot-cmdline-$(date +%y%m%d-%H%M%S)"
    "$@"  >>./kvm.stdout 2>>./kvm.stderr &
    echo "$!" >thisrun/kvm.pid
}

mount-image()
{
    local installdir="$1"
    local imagename="$2"
    partion="$3"
    options="$4"
    # (1) mkdir mntpoint, (2) kpartx, (3) mount
    cd "$installdir"
    
    
    if [ -d mntpoint ]
    then
	rmdir mntpoint || reportfail "something is already mounted at mntpoint"
    fi
    try mkdir mntpoint
    
    loopstatus="$(sudo losetup -a)"
    if [[ "$loopstatus"  == *$(pwd -P)/$imagename* ]]
    then
	reportfail "Image file is already mounted."
    else
	rm -f kpartx.out
	try sudo kpartx -av "$installdir/$imagename" 1>kpartx.out
    fi
    
    loopstatus2="$(sudo losetup -a)"
    # lines look like this:
    # /dev/loop0: [0801]:3018908 (/home/potter/winraw/windows-expanded2/windows2012-GEN-sparsed.raw)
    parse1="${loopstatus2%*$(pwd -P)/$imagename*}" # /dev/loop0: [0801]:3018908 (
    parse2="${parse1##*/dev/}"  # loop0: [0801]:3018908 (
    loopdev="${parse2%%:*}" # loop0
    
    [ "${loopdev/[0-9]/}" = "loop" ] || reportfail "could not parse $loopstatus2"
    echo "$loopdev" >loopdev
    
    sudo mount /dev/mapper/${loopdev}p${partion} mntpoint $options
}

umount-image()
{
    loopdev="$(cat ./loopdev 2>/dev/null)" || reportfail "could not read ./loopdev"
    sudo umount mntpoint
    sudo kpartx -dv /dev/$loopdev
    sudo losetup -d /dev/$loopdev
    # next line assumes nobody else is using loop mounts
    loopcheck="$(sudo losetup -a)"
    [ "$loopcheck" = "" ] || reportfail "Still loopback devices in use. Either umounting failed or they were created by other processes."
}

# potentially interesting logs and directories for debugging
windowsLogs=(
    Windows/DtcInstall.log
    Windows/inf/setupapi.app.log
    Windows/Panther
    Windows/setupact.log
    Windows/System32/sysprep
    Windows/TSSysprep.log
    Windows/WindowsUpdate.log
    Windows/Setup
    "'Program Files/ZABBIX Agent/zabbix_agentd.conf'"
)

tar-up-windows-logs()
{
    target="$1"
    [ -d mntpoint/Windows ] || reportfail "Windows disk image not mounted"
    # eval is needed to deal with the quotes needed for spaces in a file name
    eval tar czvf "$target" -C mntpoint "${windowsLogs[@]}"
    cp $(pwd)/qemu-vlan0.pcap "${target%.tar.gz}.pcap"
}

mount-tar-umount()
{
    partitionNumber=2
    mount-image "$(pwd)" "$WINIMG" $partitionNumber "-o ro"
    tar-up-windows-logs "$1"
    umount-image
}

confirm-sysprep-shutdown()
{
    # TODO: automate this
    [ -d /proc/$(< thisrun/kvm.pid) ] && reportfail "KVM still running"
    echo "Did sysprep succeed? (YES/n)"
    read ans
    [ "$ans" = "YES" ] || exit 255
}

set -x

VIRTIOISO="virtio-win-0.1-74.iso"  # version of virtio disk and network drivers known to work
ZABBIXEXE="zabbix_agent-1.8.15-1.JP_installer.exe"

case "$1" in
    *8*)
	WINIMG=win-2008.raw
	ANSFILE=Autounattend-08.xml
	WINISO=SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_Japanese_w_SP1_MLF_X17-22600.ISO
	UD=8 # unique digit
	LABEL=2008
	;;
    *12*)
	WINIMG=win-2012.raw
	ANSFILE=Autounattend-12.xml
	WINISO=SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_Japanese_-3_MLF_X19-53644.ISO
	UD=9 # unique digit
	LABEL=2012
	;;
    *)
	usage
	;;
esac

case "$1" in # allow a couple more test VMs to run in parallel
    *8b*)
	UD=6 # unique digit
	;;
    *12b*)
	UD=7 # unique digit
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
portforward="$portforward,hostfwd=tcp:0.0.0.0:10050-:10050"  # zabbix
portforward="$portforward,hostfwd=tcp:0.0.0.0:10051-:10051"  # zabbix

scriptArray=(
    wakame-init-first-boot.ps1
    sysprep-for-backup.cmd
    SetupComplete-firstboot.cmd
    SetupComplete-install.cmd
    wakame-init-every-boot.cmd
    wakame-init-every-boot.ps1
    wakame-functions.ps1
)

install-windows-from-iso()
{
    # Copy Autounattend.xml into fresh floppy image
    FLP="./answerfile-floppy.img"
    dd if=/dev/zero of="$FLP" bs=1k count=1440
    mkfs.vfat "$FLP"
    mkdir -p "./mnt"
    sudo mount -t vfat -o loop $FLP "./mnt"
    sudo cp "$SCRIPT_DIR/$ANSFILE" "./mnt/Autounattend.xml"
    for fn in "${scriptArray[@]}" FinalStepsForInstall.cmd Unattend-for-first-boot.xml $ZABBIXEXE ; do
	sudo cp "$SCRIPT_DIR/$fn" "./mnt/"
    done

    # Here we are inserting code at the start of the script that runs
    # sysprep so that it first sets the product key.  An alternative
    # would have been to set it in the answer file, but we are trying
    # to keep the answer file as simple as possible.  Another
    # alternative seemed to be to use FinalStepsForInstall.cmd, but
    # for some reason that did not work.
    # Also adding the call to the zabbix installer here so that the base
    # version of the run-sysprep.cmd file does not hard code the exact name
    # of the zabbix installer.
    prodkey="$(cat keyfile)" || reportfail "File named \"keyfile\" with MAK product key must be in the current directory"
    {
	echo "A:$ZABBIXEXE"
	echo "cscript //b c:\windows\system32\slmgr.vbs /ipk $prodkey"
	echo
	cat "$SCRIPT_DIR/run-sysprep.cmd"
    } | sudo tee ./mnt/run-sysprep.cmd

    sudo umount "./mnt"
    
    # Create 30GB image
    rm -f "$WINIMG"
    qemu-img create -f raw "$WINIMG" 30G

    if [ "$NATNET" = "" ] ; then
	boot-and-log-kvm-boot kvm $(boot-common-params) \
			      -fda "$FLP" \
			      -drive file="$SCRIPT_DIR/$WINISO",index=2,media=cdrom \
			      -drive file="$SCRIPT_DIR/$VIRTIOISO",index=3,media=cdrom \
			      -boot d \
			      -net nic,vlan=0,macaddr=$MACADDR \
			      -net socket,vlan=0,mcast=230.0.$UD.1:12341
    else
	mv qemu-vlan0.pcap "$(date +%y%m%d-%H%M%S)"-qemu-vlan0.pcap
	boot-and-log-kvm-boot kvm $(boot-common-params) \
			      -fda "$FLP" \
			      -drive file="$SCRIPT_DIR/$WINISO",index=2,media=cdrom \
			      -drive file="$SCRIPT_DIR/$VIRTIOISO",index=3,media=cdrom \
			      -boot d \
			      -net nic,vlan=0,model=virtio,macaddr=$MACADDR \
			      -net dump,vlan=0 \
			      -net user,vlan=0${portforward}
    fi
}

boot-without-networking()
{
    configure-metadata-disk
    mv qemu-vlan0.pcap "$(date +%y%m%d-%H%M%S)"-qemu-vlan0.pcap
    boot-and-log-kvm-boot kvm $(boot-common-params) \
			  -drive file="metadata.img",id=metadata-drive,cache=none,aio=native,if=none \
			  -device virtio-blk-pci,id=metadata,drive=metadata-drive,bus=pci.0,addr=0x5 \
			  -net nic,vlan=0,macaddr=$MACADDR \
			  -net dump,vlan=0 \
			  -net socket,vlan=0,mcast=230.0.$UD.1:12341
}

boot-with-networking()
{
    configure-metadata-disk
    mv qemu-vlan0.pcap "$(date +%y%m%d-%H%M%S)"-qemu-vlan0.pcap
    boot-and-log-kvm-boot kvm $(boot-common-params) \
			  -drive file="metadata.img",id=metadata-drive,cache=none,aio=native,if=none \
			  -device virtio-blk-pci,id=metadata,drive=metadata-drive,bus=pci.0,addr=0x5 \
			  -net nic,vlan=0,model=virtio,macaddr=$MACADDR \
			  -net dump,vlan=0 \
			  -net user,vlan=0${portforward}
}

# from: http://blog.vmsplice.net/2011/04/how-to-capture-vm-network-traffic-using.html
# $ qemu -net nic,model=e1000 -net dump,file=/tmp/vm0.pcap -net user
# $ /usr/sbin/tcpdump -nr /tmp/vm0.pcap

get-decode-password()
{
    mount-image "$(pwd)" metadata.img 1 "-o ro"
    if [ -f "mntpoint/meta-data/pw.enc" ]
    then
	pwtxt="$(openssl rsautl -decrypt -inkey testsshkey -in mntpoint/meta-data/pw.enc -oaep)"
	echo "$pwtxt"
    elif [ -f "mntpoint/pw.enc" ] # old location, for checking images from older tests
    then
	pwtxt="$(openssl rsautl -decrypt -inkey testsshkey -in mntpoint/pw.enc -oaep)"
	echo "$pwtxt"
    else
	set +x
	echo
	echo "---encrypted file not available yet---"
    fi
    umount-image 2>/dev/null 1>/dev/null
}


if [ "$2" == "-next" ]
then
    cmd="$(< thisrun/nextstep)"
else
    cmd="$2"
fi

genCount="${cmd#*gen}"
genCount="${genCount%%-*}"

case "$cmd" in
    -mm*) # mount metadata
	mount-image "$(pwd)" metadata.img 1
	;;
    -mtu) # *m*ount windows image, *t*ar log files, *u*mount
	[[ "$3" == *tar.gz ]] || reportfail "*.tar.gz file required for 3rd parameter"
        mount-tar-umount "$3"
	;;
    -mount)
	partitionNumber=2
	mount-image "$(pwd)" "$WINIMG" $partitionNumber "-o ro"
	;;
    -umount)
	umount-image
	;;
    -testoff)
	boot-without-networking
	;;
    -test)
	boot-with-networking
	;;
    -pw)
	get-decode-password
	;;
    ### from here start new framework
    0-init)
	for iso in "$WINISO" "$VIRTIOISO" ; do
	    [ -f "$SCRIPT_DIR/$iso" ] || reportfail "Must first copy $iso to $SCRIPT_DIR"
	done
	[ -f ./keyfile ] || reportfail "Must first create the file ./keyfile with 5X5 product key"
	for (( i=0 ; i<10000 ; i++ )) ; do
	    trythis="$(printf "run-$LABEL-%03d" $i)"
	    [ -d "$trythis" ] && continue
	    mkdir "$trythis"
	    rm -f thisrun
	    ln -s "$trythis" thisrun
	    echo "1-install" >thisrun/nextstep
	    echo "$(date +%y%m%d-%H%M%S)" >thisrun/timestamp
	    echo "This directory will make more sense if you sort by the files by date: ls -lt" >thisrun/README
	    break
	done
	;;
    1-install)
	install-windows-from-iso
	echo "1b-record-logs-at-ctr-alt-delete-prompt-gen0" >thisrun/nextstep
	;;
    1b-record-logs-at-ctr-alt-delete-prompt-gen0)
	mount-tar-umount thisrun/at-$cmd.tar.gz
	echo "2-confirm-sysprep-gen0" >thisrun/nextstep
	echo "Login with 'a:run-sysprep', then run sysprep"
	;;
    2-confirm-sysprep-gen0)
	confirm-sysprep-shutdown
	mount-tar-umount thisrun/after-gen0-sysprep.tar.gz
	echo "3-tar-the-image" >thisrun/nextstep
	;;
    3-tar-the-image)
	time md5sum "$WINIMG" >"$WINIMG".md5
	time tar czSvf "windows-$LABEL-$(cat thisrun/timestamp)".tar.gz "$WINIMG" "$WINIMG".md5
	cp -al "windows-$LABEL-$(cat thisrun/timestamp)".tar.gz thisrun
	mount-tar-umount thisrun/after-gen0-sysprep.tar.gz
	echo "1001-gen0-first-boot" >thisrun/nextstep
	;;
    1001-gen*-first-boot)
	mount-tar-umount thisrun/before-$cmd.tar.gz
	[ "$NATNET" = "" ] && boot-without-networking || boot-with-networking
	echo "1002-confirm-gen$genCount-shutdown-get-pw" >thisrun/nextstep
	;;
    1002-confirm-gen*-shutdown-get-pw)
	[ -d /proc/$(< thisrun/kvm.pid) ] && reportfail "KVM still running"
	mount-tar-umount thisrun/after-$cmd.tar.gz
	get-decode-password | tee thisrun/pw
	echo "1003-gen$genCount-second-boot" >thisrun/nextstep
	;;
    1003-gen*-second-boot)
	try 'thepid="$(cat thisrun/kvm.pid)"'
	kill -0 $thepid && reportfail "expecting KVM not to be already running"
	[ "$NATNET" = "" ] && boot-without-networking || boot-with-networking
	echo "1003b-record-logs-at-ctr-alt-delete-prompt1-gen$genCount" >thisrun/nextstep
	;;
    1003b-record-logs-at-ctr-alt-delete-prompt1-gen*)
	mount-tar-umount thisrun/at-$cmd.tar.gz
	echo "1004-confirm-gen$genCount-shutdown" >thisrun/nextstep
	echo "Password is '$(< thisrun/pw)'"
	;;
    1004-confirm-gen*-shutdown)
	[ -d /proc/$(< thisrun/kvm.pid) ] && reportfail "KVM still running"
	mount-tar-umount thisrun/after-$cmd.tar.gz
	[ "$NATNET" = "" ] && boot-without-networking || boot-with-networking
	echo "1004b-record-logs-at-ctr-alt-delete-prompt2-gen$genCount" >thisrun/nextstep
	echo "Rebooting"
	;;
    1004b-record-logs-at-ctr-alt-delete-prompt2-gen*)
	mount-tar-umount thisrun/at-$cmd.tar.gz
	echo "1005-confirm-gen$genCount-sysprep-shutdown" >thisrun/nextstep
	echo "Password is still '$(< thisrun/pw)'"
	echo "Run sysprep to make backup image"
	;;
    1005-confirm-gen*-sysprep-shutdown)
	confirm-sysprep-shutdown
	mount-tar-umount thisrun/after-$cmd.tar.gz
	echo "1001-gen$((genCount + 1))-first-boot" >thisrun/nextstep
	;;
    *)
	reportfail "Invalid command for 2nd parameter"
	;;
esac
