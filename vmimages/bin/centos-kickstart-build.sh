#!/bin/bash

install_iso="$1"
kickstart_file="$2"
target_image="$3"
memory="$4"

: ${KVMSTYLE:=wakame}

reportfailed()
{
    echo "Script failed...exiting. ($*)" 1>&2
    exit 255
}

prev-cmd-failed()
{
    # this is needed because '( cmd1 ; cmd2 ; set -e ; cmd3 ; cmd4 ) || reportfailed'
    # does not work because the || disables set -e, even inside the subshell!
    # see http://unix.stackexchange.com/questions/65532/why-does-set-e-not-work-inside
    # A workaround is to do  '( cmd1 ; cmd2 ; set -e ; cmd3 ; cmd4 ) ; prev-cmd-failed'
    (($? == 0)) || reportfailed "$*"
}

# Minimal parameter checking to catch typos:
[ -f "$install_iso" ] || reportfailed "Iso ($install_iso) not found."
[[ "$install_iso" == *.iso ]] || \
    [[ "$install_iso" == *.ISO ]] || reportfailed "First parameter does not end in .iso"

[ -f "$kickstart_file" ] || reportfailed "Iso ($kickstart_file) not found."
[[ "$kickstart_file" == *.cfg ]] || reportfailed "First parameter does not end in .cfg"

[ -f "$target_image" ] && reportfailed "$target_image already exists"

[[ "$memory" == *M ]] || reportfailed "Fourth parameter (memory) should end with M, e.g. 1024M"

# Make sure it is writable
touch "$target_image" || reportfailed "Could not create '$target_image' (the third parameter)"

export TARGET_DIR="$(cd "$(dirname "$(readlink -f "$target_dir")")" && pwd -P)" || reportfailed

KSFPY="$TARGET_DIR/kickstart_floppy.img"

(
    set -e
    dd if=/dev/zero of="$KSFPY" count=1440 bs=1k
    /sbin/mkfs.msdos "$KSFPY"
    mcopy -i "$KSFPY" "$kickstart_file" ::/ks.cfg
    mdir -i "$KSFPY"
) ; prev-cmd-failed "Problem while creating floppy with kickstart file"


(
    set -e
    rm -f "$target_image"
    qemu-img create -f raw "$target_image" 10000M
) ; prev-cmd-failed "Problem while creating empty raw image"

binlist=(
    /usr/libexec/qemu-kvm
    /usr/bin/qemu-kvm
)
for i in "${binlist[@]}"; do
    if [ -f "$i" ]; then
	KVMBIN="$i"
	break
    fi
done


# TODO: parameterize more of the KVM parameters
case "$KVMSTYLE" in
    packer)
	# this command line comes from modifying what packer used
	kvmcmdline=(
	    "$KVMBIN"
	    -name ksvm
	    
	    -fda "$KSFPY"
	    -device virtio-net,netdev=user.0
	    -drive "file=$target_image,if=virtio,cache=writeback,discard=ignore"
	    
	    -m "$memory"
	    -machine type=pc,accel=kvm
	    
	    -netdev user,id=user.0,hostfwd=tcp::2224-:22
	    -monitor telnet:0.0.0.0:4567,server,nowait
	    -vnc 0.0.0.0:47
	)
	;;
    wakame)
	# The packer cmdline does not work with the verson of KVM
	# installed with Wakame-vdc. For example, it complains about
	# ",discard=ignore" and the -device parameter. So here is another
	# cmdline that is based on one used by Wakame-vdc.
	kvmcmdline=(
	    "$KVMBIN"
	    -fda "$KSFPY"

	    -m "$memory"
	    -smp 2
	    -name vdc-i-45pkc5fd
	    
#	    -pidfile /var/lib/wakame-vdc/instances/i-45pkc5fd/kvm.pid
#	    -daemonize
#	    -monitor telnet:127.0.0.1:29684,server,nowait
	    
	    -monitor telnet:127.0.0.1:4567,server,nowait
	    -no-kvm-pit-reinjection
#	    -vnc 127.0.0.1:26857
    	    -vnc 127.0.0.1:47
#	    -serial telnet:127.0.0.1:32479,server,nowait
	    -serial telnet:127.0.0.1:4568,server,nowait
	    -drive "file=$target_image,id=vol-tu3y7qj4-drive,if=none,serial=vol-tu3y7qj4,cache=none,aio=native"
	    -device virtio-blk-pci,id=vol-tu3y7qj4,drive=vol-tu3y7qj4-drive,bootindex=0,bus=pci.0,addr=0x4
	    
#	    -drive file=/var/lib/wakame-vdc/instances/i-45pkc5fd/metadata.img,id=metadata-drive,if=none,serial=metadata,cache=none,aio=native
#	    -device virtio-blk-pci,id=metadata,drive=metadata-drive,bus=pci.0,addr=0x5
	    
	    -net nic,vlan=0,macaddr=52:54:00:65:28:dd,model=virtio,addr=10
#	    -net tap,vlan=0,ifname=vif-b5h2nea0,script=no,downscript=no
	    -net user,vlan=0,hostfwd=tcp::2224-:22
	)
	;;
    *) reportfailed '$KVMSTYLE'
       ;;
esac

cat >runscript.sh <<EOF
${kvmcmdline[@]} &
echo "\$!" >kvm.pid
wait
EOF

chmod +x runscript.sh

"${kvmcmdline[@]}" -boot once=d -cdrom "$install_iso" >kvm.stdout 2>kvm.stderr &
echo "$!" >kvm.pid

sleep 15

# Old versions of KVM do not support shift-semicolon or semicolon, so
# starting with 'keypresses="tab spc k s equal" bash -x ./build.sh'
# will allow the rest initial command line to be typed in manually.
# A VNC based solution is also possible, but not currently implemented.

# the need for the selinux keys is explained here:
# http://serverfault.com/questions/340679/centos-6-kickstart-ignoring-selinux-disabled
[ "$keypresses" = "" ] && \
    selinux="s e l i n u x equal 0 spc"
    keypresses="tab spc $selinux k s equal h d shift-semicolon f d 0 shift-semicolon  slash k s dot c f g ret"


# send "<tab><space>ks=hd:fd0:/ks.cfg"
for k in $keypresses
do
    echo sendkey $k | nc 127.0.0.1 4567
    sleep 1
done
echo "Finished sending key presses"

# NOTE: Sometimes all the keys above are typed OK and the ks.cfg file
# is read in OK, but the installation does not start until the user
# clicks on the "Begin" button.  One possible cause could be the VNC
# windows being open and some UI events being sent to the graphical
# installer, which senses the human there and politely asks for
# confirmation.

# Update: Nope. Did not work even with no vncviewer connected.  Looks like
# alt-B will select that button.  Seems to take at least 20 seconds to get
# to that screen so....

sleep 60
echo sendkey alt-b | nc 127.0.0.1 4567

echo
echo "Just sent an extra alt-b just in case"
echo "it is stuck on the confirm install screen"
echo
echo "Now waiting for kvm to exit. (FYI, ^c will kill KVM)"
wait

# discover the supported keys by doing:
#   telnet 127.0.0.1 4567
#   sendkey <tab>
# Here is the result:
# (qemu) sendkey 
# 0              1              2              3              4              
# 5              6              7              8              9              
# a              again          alt            alt_r          altgr          
# altgr_r        apostrophe     asterisk       b              backslash      
# backspace      bracket_left   bracket_right  c              caps_lock      
# comma          compose        copy           ctrl           ctrl_r         
# cut            d              delete         dot            down           
# e              end            equal          esc            f              
# f1             f10            f11            f12            f2             
# f3             f4             f5             f6             f7             
# f8             f9             find           front          g              
# grave_accent   h              help           home           i              
# insert         j              k              kp_0           kp_1           
# kp_2           kp_3           kp_4           kp_5           kp_6           
# kp_7           kp_8           kp_9           kp_add         kp_decimal     
# kp_divide      kp_enter       kp_multiply    kp_subtract    l              
# left           less           lf             m              menu           
# meta_l         meta_r         minus          n              num_lock       
# o              open           p              paste          pause          
# pgdn           pgup           print          props          q              
# r              ret            right          s              scroll_lock    
# semicolon      shift          shift_r        slash          spc            
# stop           sysrq          t              tab            u              
# undo           unmapped       up             v              w              
# x              y              z              
