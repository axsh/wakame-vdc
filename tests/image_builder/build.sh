#!/bin/bash
rootsize=500
swapsize=128

set -e

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >2
  exit 1
}


function run_vmbuilder() {
  typeset imgpath=$1
  typeset arch=$2 # i386, amd64
  
  [[ -d ./ubuntu-kvm ]] && rm -rf ./ubuntu-kvm

  [[ -f $imgpath ]] && rm -f $imgpath

  echo "Creating image file... $imgpath"
  truncate -s $(( $rootsize + $swapsize - 1))m $imgpath
  vmbuilder kvm ubuntu --suite=lucid --mirror=http://archive.ubuntu.com/ubuntu \
      --raw=$imgpath --rootsize $rootsize --swapsize $swapsize --variant minbase \
      --addpkg ssh --addpkg curl \
      --addpkg sudo \
      --addpkg iproute \
      --addpkg dhcp-client \
      --addpkg iputils-ping \
      --addpkg telnet \
      --addpkg libterm-readline-perl-perl \
      --addpkg ifmetric \
      --addpkg vim \
      --addpkg less \
      --addpkg lv \
      --addpkg gpgv \
      --dns 8.8.8.8 --arch=$arch
}

# loop mounts the image file and calls a shell function during mounting.
#
# % loop_mount_image "new.raw" "shell_func_name" ["opt1" "opt2"...]
function loop_mount_image() {
  typeset image_path="$1"
  typeset eval_cb="$2"
  shift; shift;

  typeset lodev=`losetup -f "${image_path}" --show`
  typeset lodev_name=`basename $lodev`

  kpartx -a $lodev
  udevadm settle

  typeset tmp_root=./loop
  [[ -d $tmp_root ]] || mkdir $tmp_root
  mount "/dev/mapper/${lodev_name}p1" $tmp_root
  
  eval "${eval_cb} $tmp_root $lodev $@"

  umount -f $tmp_root
  kpartx -d $lodev
  udevadm settle
  losetup -d $lodev

  rmdir $tmp_root
}

#
# Callback function for loop_mount_image().
function install_wakame_init() {
  typeset tmp_root="$1"
  typeset lodev="$2"
  typeset wakame_init_path="$3"
  typeset metadata_type="$4"

  #Install the startup script
  echo "Installing the startup script: `basename ${wakame_init_path}`"
  # The script name may vary by the metadata source type. 
  # I keep the script name.
  typeset wakame_init_name=`basename $wakame_init_path`
  cp -p $wakame_init_path $tmp_root/etc/
  chmod 755 $tmp_root/etc/$wakame_init_name
  chown 0:0 $tmp_root/etc/$wakame_init_name

  case ${metadata_type} in
  ms|server)
    metadata_type=ms
    ;;
  md|drive)
    metadata_type=md
    ;;
  *)
    # default value is "drive|md" in wakame-init
    metadata_type=
    ;;
  esac

  cat <<EOF > $tmp_root/etc/rc.local
/etc/wakame-init ${metadata_type}
exit 0
EOF
}

# Callback function for loop_mount_image().
# 
function kvm_base_setup() {
  typeset tmp_root="$1"
  typeset lodev="$2"

  typeset lodev_name=`basename $lodev`

  # extract partition UUIDs.
  typeset p1uuid=`blkid "/dev/mapper/${lodev_name}p1" | awk -F'"' '{print $2}'`
  typeset p2uuid=`blkid "/dev/mapper/${lodev_name}p2" | awk -F'"' '{print $2}'`

  #Remove SSH host keys
  echo "Removing ssh host keys"
  rm -f $tmp_root/etc/ssh/ssh_host*
  
  #Update fstab to use UUID.
  sed -e "s/^\/dev\/sda1/UUID=${p1uuid}/" \
    -e "s/^\/dev\/sda2/UUID=${p2uuid}/" \
    $tmp_root/etc/fstab > ./fstab
  mv ./fstab $tmp_root/etc/fstab
  
  # disable mac address caching
  echo "Unsetting udev 70-persistent-net.rules"
  rm -f $tmp_root/etc/udev/rules.d/70-persistent-net.rules
  ln -s /dev/null $tmp_root/etc/udev/rules.d/70-persistent-net.rules

  # append virtual interface ignore rules to 75-persistent-net-generator.rules.
  # * udev creates persistent network rule for KVM virtual interface: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=638159
  # * udev: Additional VMware MAC ranges for 75-persistent-net-generator.rules: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=637571
  sed -e '/^ENV{MATCHADDR}=="00:00:00:00:00:00", ENV{MATCHADDR}=""/a \
# and KVM, Hyper-V and VMWare virtual interfaces\
ENV{MATCHADDR}=="?[2367abef]:*",       ENV{MATCHADDR}=""\
ENV{MATCHADDR}=="00:00:00:00:00:00",   ENV{MATCHADDR}=""\
ENV{MATCHADDR}=="00:05::69:*|00:0c:29:*|00:50:56:*|00:1C:14:*", ENV{MATCHADDR}=""\
ENV{MATCHADDR}=="00:15:5d:*",          ENV{MATCHADDR}=""\
ENV{MATCHADDR}=="52:54:00:*|54:52:00:*", ENV{MATCHADDR}=""\
' < $tmp_root/lib/udev/rules.d/75-persistent-net-generator.rules > 75-persistent-net-generator.rules
  mv 75-persistent-net-generator.rules $tmp_root/lib/udev/rules.d/75-persistent-net-generator.rules
  
  #Load acpiphp.ko at boot
  echo "Adding acpiphp to kernel modules to load at boot"
  echo "acpiphp" >> $tmp_root/etc/modules

  echo "Disabling sshd PasswordAuthentication"
  sed -e '/^PasswordAuthentication.*yes/ c\
PasswordAuthentication no
' < $tmp_root/etc/ssh/sshd_config > ./sshd_config.tmp

  egrep '^PasswordAuthentication' ./sshd_config.tmp -q || {
    sed -e '$ a\
PasswordAuthentication no' ./sshd_config.tmp > ./sshd_config
  }
  mv ./sshd_config $tmp_root/etc/ssh/sshd_config
  rm -f ./sshd_config.tmp
}

# Callback function for loop_mount_image().
# 
function lxc_base_setup() {
  typeset tmp_root="$1"
  typeset lodev="$2"

  typeset lodev_name=`basename $lodev`

  # uninstall udev
  #DEBIAN_FRONTEND=noninteractive dpkg --root=$tmp_root -r grub plymouth mountall initramfs-tools dmsetup udev
}

# generate seed image
run_vmbuilder "ubuntu-lucid-32.raw" "i386"
run_vmbuilder "ubuntu-lucid-64.raw" "amd64"

# no metadata image (KVM)
cp --sparse=auto "ubuntu-lucid-32.raw" "ubuntu-lucid-kvm-32.raw"
cp --sparse=auto "ubuntu-lucid-64.raw" "ubuntu-lucid-kvm-64.raw"

loop_mount_image "ubuntu-lucid-kvm-32.raw" "kvm_base_setup"
loop_mount_image "ubuntu-lucid-kvm-64.raw" "kvm_base_setup"


# metadata server image (KVM)
cp --sparse=auto "ubuntu-lucid-kvm-32.raw" "ubuntu-lucid-kvm-ms-32.raw"
cp --sparse=auto "ubuntu-lucid-kvm-64.raw" "ubuntu-lucid-kvm-ms-64.raw"

loop_mount_image "ubuntu-lucid-kvm-ms-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"
loop_mount_image "ubuntu-lucid-kvm-ms-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"

# metadata drive image (KVM)
cp --sparse=auto "ubuntu-lucid-kvm-32.raw" "ubuntu-lucid-kvm-md-32.raw"
cp --sparse=auto "ubuntu-lucid-kvm-64.raw" "ubuntu-lucid-kvm-md-64.raw"

loop_mount_image "ubuntu-lucid-kvm-md-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
loop_mount_image "ubuntu-lucid-kvm-md-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"

exit 0

# no metadata image (LXC)
cp --sparse=auto "ubuntu-lucid-32.raw" "ubuntu-lucid-lxc-32.raw"
cp --sparse=auto "ubuntu-lucid-64.raw" "ubuntu-lucid-lxc-64.raw"

loop_mount_image "ubuntu-lucid-lxc-32.raw" "lxc_base_setup"
loop_mount_image "ubuntu-lucid-lxc-64.raw" "lxc_base_setup"

# metadata server image (LXC)
cp --sparse=auto "ubuntu-lucid-lxc-32.raw" "ubuntu-lucid-lxc-ms-32.raw"
cp --sparse=auto "ubuntu-lucid-lxc-64.raw" "ubuntu-lucid-lxc-ms-64.raw"

loop_mount_image "ubuntu-lucid-lxc-ms-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"
loop_mount_image "ubuntu-lucid-lxc-ms-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"

# metadata drive image (LXC)
cp --sparse=auto "ubuntu-lucid-lxc-32.raw" "ubuntu-lucid-lxc-md-32.raw"
cp --sparse=auto "ubuntu-lucid-lxc-64.raw" "ubuntu-lucid-lxc-md-64.raw"

loop_mount_image "ubuntu-lucid-lxc-md-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
loop_mount_image "ubuntu-lucid-lxc-md-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
