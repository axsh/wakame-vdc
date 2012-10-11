#!/bin/bash

set -e

#TODO: do this cleaner with an argument
function run_vmbuilder_hva() {
  typeset imgpath=$1
  typeset arch=$2 # i386, amd64

  local tmp_script_path=/${tmp_path}/hva_script.sh

  [[ -d ./ubuntu-kvm ]] && rm -rf ./ubuntu-kvm

  [[ -f $imgpath ]] && rm -f $imgpath

  # Create the startup script that installs custom packages and upgrades on first boot
  cat <<EOF > $tmp_script_path
#!/bin/bash

mkdir -p /root/.ssh/
cat <<'EOS' > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZhAOcHSe4aY8GwwLCJ4Et3qUBcyVPokFoCyCrtTZJVUU++B9554ahiVcrQCbfuDlaXV2ZCfIND+5N1UEk5umMoQG1aPBw9Nz9wspMpWiTKGOAm99yR9aZeNbUi8zAfyYnjrpuRUKCH1UPmh6EDaryFNDsxInmaZZ6701PgT++cZ3Vy/r1bmb93YvpV+hfaL/FmY3Cu8n+WJSoJQZ4eCMJ+4Pw/pkxjfuLUw3mFl40RVAlwlTuf1I4bB/m1mjlmirBEU6+CWLGYUNWDKaFBpJcGB6sXoQDS4FvlV92tUAEKIBWG5ma0EXBdJQBi1XxSCU2p7XMX8DhS7Gj/TSu7011 wakame-vdc.pem
EOS

#apt-get update
#apt-get -y upgrade
cd /root/custom_pkgs
dpkg -i *.deb

dpkg-reconfigure openssh-server

#temp ugly patch
sed -i 's/eventmachine (1.0.0.beta.3)/eventmachine (1.0.0.beta.4)/g' /root/wakame-vdc/dcmgr/Gemfile.lock
sed -i 's/eventmachine (= 1.0.0.beta.3)/eventmachine (= 1.0.0.beta.4)/g' /root/wakame-vdc/dcmgr/Gemfile.lock

gem install rubygems-update
/var/lib/gems/1.8/bin/update_rubygems

gem install bundler
cd /root/wakame-vdc/dcmgr
bundle install

touch /root/firstboot_done
EOF

  echo "Creating image file... $imgpath"
  truncate -s $(( $rootsize + $swapsize - 1))m $imgpath
  shlog "vmbuilder kvm ubuntu --suite=lucid --mirror=http://jp.archive.ubuntu.com/ubuntu \
      --raw=$imgpath --rootsize $rootsize --swapsize $swapsize --variant minbase \
      --addpkg linux-image-3.0.0-15-server \
      --addpkg ssh \
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
      --addpkg ebtables \
      --addpkg iptables \
      --addpkg ipset \
      --addpkg ethtool \
      --addpkg vlan \
      --addpkg openssh-server \
      --addpkg openssh-client \
      --addpkg ruby \
      --addpkg ruby-dev \
      --addpkg libopenssl-ruby1.8 \
      --addpkg ruby1.8 \
      --addpkg rubygems1.8 \
      --addpkg rdoc1.8 \
      --addpkg irb1.8 \
      --addpkg g++ \
      --addpkg curl \
      --addpkg libcurl4-openssl-dev \
      --addpkg mysql-server \
      --addpkg mysql-client \
      --addpkg libmysqlclient16-dev \
      --addpkg rabbitmq-server \
      --addpkg qemu-kvm \
      --addpkg kvm-pxe \
      --addpkg ubuntu-vm-builder \
      --addpkg dnsmasq \
      --addpkg open-iscsi \
      --addpkg open-iscsi-utils \
      --addpkg nginx \
      --addpkg libxml2-dev \
      --addpkg libxslt1-dev \
      --addpkg ipcalc \
      --addpkg dosfstools \
      --addpkg bridge-utils \
      --addpkg rsync \
      --dns 8.8.8.8 --arch=$arch \
      --firstboot $tmp_script_path"

  rm $tmp_script_path
}

function run_vmbuilder() {
  typeset imgpath=$1
  typeset arch=$2 # i386, amd64
  shift; shift;

  [[ -d ./ubuntu-kvm ]] && rm -rf ./ubuntu-kvm

  [[ -f $imgpath ]] && rm -f $imgpath

  echo "Creating image file... $imgpath"
  truncate -s $(( $rootsize + $swapsize - 1))m $imgpath
  vmbuilder kvm ubuntu --suite=lucid --mirror=http://jp.archive.ubuntu.com/ubuntu \
      --arch=$arch --raw=$imgpath --rootsize $rootsize --swapsize $swapsize --variant minbase \
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
      --dns 8.8.8.8 $@
}

function run_vmbuilder_secgtest() {
  typeset imgpath=$1
  typeset arch=$2 # i386, amd64
  shift; shift;

  [[ -d ./ubuntu-kvm ]] && rm -rf ./ubuntu-kvm

  [[ -f $imgpath ]] && rm -f $imgpath

  echo "Creating image file... $imgpath"
  truncate -s $(( $rootsize + $swapsize - 1))m $imgpath
  vmbuilder kvm ubuntu --suite=lucid --mirror=http://jp.archive.ubuntu.com/ubuntu \
      --arch=$arch --raw=$imgpath --rootsize $rootsize --swapsize $swapsize --variant minbase \
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
      --addpkg ruby \
      --addpkg rubygems \
      --dns 8.8.8.8 $@
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

function setup_hva() {
  typeset tmp_root="$1"
  typeset lodev="$2"
  typeset hva_id="$3"
  typeset vhva_ip="$4"
  #typeset hva_netmask="$5"
  #typeset hva_gateway="$6"
  #typeset hva_dns="$7"

  #TODO: get a better directory for this
  custom_pkg_dir=${tmp_path}/custom_pkg_dir

  #TODO:calculate broadcast and network
  #hva_network="192.168.2.0"
  #hva_broadcast="192.168.2.255"

  # Set up the network
  cat <<EOF > $tmp_root/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet manual
        up /sbin/ifconfig eth0 promisc

auto br0
iface br0 inet static
        address $vhva_ip
        netmask $vhva_netmask
        network $vhva_network
        broadcast $vhva_broadcast
        gateway $vhva_gateway
        dns-nameservers 8.8.8.8 8.8.8.4 $vhva_dns
        bridge_ports eth0
        bridge_stp off
        bridge_fd 0
        bridge_maxwait 1
EOF

  # Prepare wakame custom packages. These will be installed when the VM is first booted
  if [ ! -d $custom_pkg_dir ]; then
    mkdir -p $custom_pkg_dir
    cd $custom_pkg_dir

    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/dnsmasq-base_2.57-1ubuntu1_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/dnsmasq-utils_2.57-1ubuntu1_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/dnsmasq_2.57-1ubuntu1_all.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/kvm_84+dfsg-0ubuntu16+0.14.1+noroms+0ubuntu6backport1_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/kvm_84+dfsg-0ubuntu16+0.14.1+noroms+0ubuntu6backport2_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu-common_0.14.1+noroms-0ubuntu6backport1_all.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu-common_0.14.1+noroms-0ubuntu6backport2_all.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu-kvm_0.14.1+noroms-0ubuntu6backport1_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu-kvm_0.14.1+noroms-0ubuntu6backport2_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu_0.14.1+noroms-0ubuntu6backport1_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/qemu_0.14.1+noroms-0ubuntu6backport2_amd64.deb
    #wget http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/ubuntu/wakame-vdc/archive/vgabios_0.6c-2ubuntu3_all.deb
  fi
  shlog "mkdir -p $tmp_root/root/custom_pkgs"
  shlog "cp $custom_pkg_dir/*.deb $tmp_root/root/custom_pkgs"

  shlog "mkdir -p ${tmp_root}/root/wakame-vdc/tmp/instances"
  shlog "cp -r ${prefix_path}/dcmgr ${tmp_root}/root/wakame-vdc"
  cat <<EOF > ${tmp_root}/root/wakame-vdc/dcmgr/config/hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
config.vm_data_dir = "/root/wakame-vdc/tmp/instances"

config.edge_networking = "netfilter"

# netfilter
config.enable_ebtables = true
config.enable_iptables = true
config.enable_openflow = false

# physical nic index
config.hv_ifindex      = 2 # ex. /sys/class/net/eth0/ifindex => 2

# bridge device name prefix
config.bridge_prefix   = 'br'

# bridge device name novlan
config.bridge_novlan   = 'br0'

# display netfitler commands
config.verbose_netfilter = true
config.verbose_openflow  = false

# netfilter log output flag
config.packet_drop_log = false

# debug netfilter
config.debug_iptables = false

# Use ipset for netfilter
config.use_ipset       = false

# Path for brctl
config.brctl_path = '/usr/sbin/brctl'

# Directory used by Open vSwitch daemon for run files
config.ovs_run_dir = '/home/wakame/work/wakame-vdc/ovs/var/run/openvswitch'

# Path for ovs-ofctl
config.ovs_ofctl_path = '/home/wakame/work/wakame-vdc/ovs/bin/ovs-ofctl'

# Trema base directory
config.trema_dir = '/home/wakame/work/wakame-vdc/trema'
EOF

cat <<'EOS' > ${tmp_path}/vhva.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA2YQDnB0nuGmPBsMCwieBLd6lAXMlT6JBaAsgq7U2SVVFPvgf
eeeGoYlXK0Am37g5Wl1dmQnyDQ/uTdVBJObpjKEBtWjwcPTc/cLKTKVokyhjgJvf
ckfWmXjW1IvMwH8mJ466bkVCgh9VD5oehA2q8hTQ7MSJ5mmWeu9NT4E/vnGd1cv6
9W5m/d2L6VfoX2i/xZmNwrvJ/liUqCUGeHgjCfuD8P6ZMY37i1MN5hZeNEVQJcJU
7n9SOGwf5tZo5ZoqwRFOvglixmFDVgymhQaSXBgerF6EA0uBb5VfdrVABCiAVhuZ
mtBFwXSUAYtV8UglNqe1zF/A4Uuxo/00ru9NdQIDAQABAoIBAC/WHakerFadOGxH
RPsIDxvUZDuOZD1ANNw53kSFBNxZ2XHAxcNcjLpH5xjG8gWvkUVzVRtMGaSPxVvu
s3X3JpPb8PFBk+dzoopYZX83vWjnsAJfxWNvsx1reuuhlzUagXyfohaQOtE9LMrS
nTVzgA3fUBdSHfXDcOm2aS08ApXSJOIxYxD/9AF6HNBsqTe+qvHiHVy570wkc2gf
K8m90NITTefIv67YzyVNubqCa2k9AiDojRKv0MeBpMqzHA3Lyw8El6Z0RTH694aV
AM1+y760DKw3SE320p9wz/onh6mei5jg4eoGDZHqGCY4rb3U9qLkMFHPmsOssWQq
/O5056ECgYEA+y0DHYCq3bcJFxhHqogVYbSnnJTJriC4XObjMK5srz1Y9GL6mfhd
3qJIbyjgRofqLEdOUXq2LR8BVcSnWxVwwzkThtYpRlbHPMv3MPr/PKgyNj3Gsvv5
0Y2EzcLiD1cm1f5Z//EWu+mOAfzW8JOLL8w+ZedsdvCUmFrZp/eClR0CgYEA3bGA
NwWOpERSylkA3cK5XGMFYwj6cE2+EMaFqzdEy4bLKhkdLMEA1NA7CbtO46e7AvCu
sthj5Qty605uGEI6+S5M/IPlX/Gh66f3qnXXNsVKXJbOcUC9lEbRwZa0V1u1Eqrx
mJ3g1as31EgmKRv4vIJ2wQTVgorBNDuUdZUzYjkCgYA3h78Nkbm05Nd8pKCLgiSA
AmmgA4EHHzLDT0RhKd7ba0u0VAGlcrSGGQi8kqPq0/egrG8TMnb+SMGJzb1WNMpG
TuMTR1u+skbAGTPgP02YgnL/bO71+SFFA+2dc/14eMMcQmxxWkK1brA3nkeCzovS
GGyfKOfg79VaTZObP+w9vQKBgQC4dpBLt/kHX75Plh0taHAZml8KF5diyJ1Ekhr4
6wT4IJF91uW6rmFFsnndUBiFPrRR7vg94eXE2HDnsBvVXY56dfcjCZBa89CaJ+ng
0Sqg7SpBvk3KWGcmMIMqBH7MTYduIATky0EgKNZMcTgnbpnaKOgtFRufAlteXdDa
wam+qQKBgHxGg9HJI3Ax8M5rgmsGReBM8e1GHojV5pmgWm0AsX04RS/7/gNkXHdv
MoU4FfcO/Tf7b+qwp40OjN0dr7xDwIWXih2LrAxGK2Lw43hlC5huYmqpEIYoiag+
PxIk/VB7tQxkp4Rtv005mWHPUYlh8x4lMqiVAhPJzEBfN9UEfkrk
-----END RSA PRIVATE KEY-----
EOS
chmod 600 ${tmp_path}/vhva.pem

cat <<EOF > $tmp_root/etc/ssh/sshd_config
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 768
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
EOF

  #shlog 'chroot $tmp_root /root/firstboot.sh'
  #shlog "rm $tmp_root/root/firstboot.sh"
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

function install_secg_test_scripts() {
  typeset tmp_root="$1"
  typeset lodev="$2"
  typeset script_location="$3"

  echo "Installing the secgtest scripts from ${script_location}"

  for file in `ls $script_location`; do
    cp -p $script_location/$file $tmp_root/opt/$file
    chmod 755 $tmp_root/opt/$file
    chown 0:0 $tmp_root/opt/$file
  done
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
  } && {
    mv ./sshd_config.tmp ./sshd_config
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
