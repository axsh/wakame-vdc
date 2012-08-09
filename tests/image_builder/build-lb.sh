#!/bin/bash
rootsize=768
swapsize=128
distro_name=centos # [ centos | sl ]
distro_ver=6.3     # [ 6 | 6.0 | 6.1 | 6.2 | 6.x... ]
arch="x86_64"
hypervisor=${hypervisor:-'openvz'}

input_image="${distro_name}-${distro_ver}_${arch}.row"
output_image="${distro_name}-${distro_ver}_${arch}-md.row"
register_image="lb-${distro_name}-${hypervisor}-md-64.raw"

set -e
set -x

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >&2
  exit 1
}

. ./build_functions-rhel.sh

function init_openvz() {
  typeset vz_root=$1
  cat <<'EOS' | chroot $vz_root bash -c "cat | bash"
# Replace /etc/mtab file
# In virtual machine there is no physical devices to mount so replace mtab file with /proc/mounts/
rm -f /etc/mtab
ln -s /proc/mounts /etc/mtab

# Edit /etc/fstab file
# Remove all entries in /etc/fstab file except ones for /dev/pts, as below
cat <<EOF > /etc/fstab
devpts  /dev/pts  devpts  gid=5,mode=620  0 0
EOF

# Disable udev start up from /etc/rc.sysinit by commenting out next line:
sed -i -e "s,/sbin/start_udev,# /sbin/start_udev," /etc/rc.sysinit

# Create rpm lock folder
# mkdir /var/lock/rpm

  # Disable IPv6
  sed -i -e "s/NETWORKING=\"yes\"/NETWORKING=\"no\"/" /etc/sysconfig/network

  # Add following lines to etc/modprobe.d/blacklist file
  cat <<EOF > /etc/modprobe.d/blacklist
blacklist ipv6
blacklist net-pf-10
EOF

# Remove /etc/resolv.conf
# /etc/resolv.conf file will be added by vzctl command later
# rm -r /etc/resolv.conf*

# Clear network configurations from template
sed -i -e "s/ONBOOT=yes/ONBOOT=no/" /etc/sysconfig/network-scripts/ifcfg-eth*

# Otherwise when startup init script rc will enter interactive mode and wait there forever
sed -i -e "s/PROMPT=yes/PROMPT=no/" /etc/sysconfig/init
EOS

}

function load_balancer_setup() {
  typeset tmp_root="$1"
  typeset lodev="$2"
  typeset wakame_vdc_dir="$( cd ../../ && pwd )"
  typeset load_balancer_dir="${wakame_vdc_dir}/vmapp/load_balancer"
  typeset wakame_init_path="${wakame_vdc_dir}/tests/image_builder/rhel/6/wakame-init"
  typeset axsh_dir="${tmp_root}/opt/axsh"
  typeset target_dir="${axsh_dir}/wakame-vdc"

  mkdir -p ${tmp_root}/opt/axsh/wakame-vdc/scripts
  mkdir -p ${tmp_root}/opt/axsh/wakame-vdc/amqptools/bin

  cp ${load_balancer_dir}/etc/init/haproxy_updater.conf ${tmp_root}/etc/init/haproxy_updater.conf
  cp ${load_balancer_dir}/etc/init.d/stunnel ${tmp_root}/etc/init.d/stunnel
  cp ${load_balancer_dir}/scripts/update_haproxy.sh ${target_dir}/scripts/update_haproxy.sh
  cp ${load_balancer_dir}/amqptools/bin/amqpspawn ${target_dir}/amqptools/bin/amqpspawn
  cp ${wakame_init_path} ${tmp_root}/etc/wakame-init
  chmod 755 $tmp_root/etc/wakame-init
  chown 0:0 $tmp_root/etc/wakame-init

  cat <<EOF > $tmp_root/etc/rc.local
/etc/wakame-init md
initctl start haproxy_updater
exit 0
EOF

  init_openvz $tmp_root
  cat <<'EOS' | chroot $tmp_root bash -c "cat | bash"
/sbin/MAKEDEV urandom

# for HAproxy
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm

# instlall package
distro_pkgs="
 haproxy
 stunnel
"
yum install -y ${distro_pkgs}

chkconfig haproxy off
chkconfig stunnel off
rm -f /etc/haproxy/haproxy.cfg
EOS
}

[ -f "${distro_name}-${distro_ver}_${arch}.tar.gz" ] || {
  wget "http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/rootfs-tree/${distro_name}-${distro_ver}_${arch}.tar.gz"
}
[ -d "${distro_name}-${distro_ver}_${arch}" ] || {
  tar xvzf centos-6.3_x86_64.tar.gz
}

[ -f ${input_image} ] || run_vmbuilder "${input_image}" "${arch}"
cp --sparse=auto ${input_image} ${output_image}
loop_mount_image "${output_image}" "load_balancer_setup"
mv ${output_image} ${register_image}
for i in ./${register_image} ; do echo $i; time sudo bash -c "gzip -c $i > $i.gz"; done
rm -f ${output_image}
rm -f ${register_image}
