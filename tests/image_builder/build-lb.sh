#!/bin/bash
rootsize=768
swapsize=128
distro_name=centos # [ centos | sl ]
distro_ver=6.3     # [ 6 | 6.0 | 6.1 | 6.2 | 6.x... ]
arch="x86_64"
hypervisor=${hypervisor:-'openvz'}

ssl_wrapper=${ssl_wrapper:-'stud'}

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

## Will delete stunnel if we decide to use stud in the future
function build_wrapper_stunnel() {
  # Make OpenSSL
  (
    cd ${tmp_dir}
  [ -f "${tmp_dir}/openssl-1.0.1c" ]|| {
    curl -L -O http://www.openssl.org/source/openssl-1.0.1c.tar.gz
    tar xvzf ./openssl-1.0.1c.tar.gz
  }
  cd openssl-1.0.1c
  ./Configure no-share --openssldir=${tmp_dir}/openssl linux-x86_64
  make clean
  make
  make install
  )

  # Make Stunnel with OpenSSL
  (
  cd ${tmp_dir}
  [ -f "${tmp_dir}/stunnel-4.54" ]|| {
    curl -L -O http://mirrors.zerg.biz/stunnel/stunnel-4.54.tar.gz
    tar xvzf stunnel-4.54.tar.gz
  }
  cd stunnel-4.54
  ./configure --prefix=${tmp_dir}/stunnel with_ssl=${tmp_dir}/openssl
  make clean
  make
  make install-exec
  )

  mkdir -p ${tmp_root}/etc/stunnel
  mv ${tmp_dir}/stunnel/bin/stunnel ${target_dir}

  rm -rf ${tmp_dir}/openssl
  rm -rf ${tmp_dir}/stunnel
}

function build_wrapper_stud() {
  (
  libev_name="libev-4.11"
  libev_tarball="${libev_name}.tar.gz"

  ## Make libev
  cd ${tmp_dir}
  [ -f ${libev_tarball}  ] || wget http://dist.schmorp.de/libev/${libev_tarball}
  tar xvzf ${libev_tarball}
  cd ${libev_name}
  ./configure
  make

  cp ${tmp_dir}/${libev_name}/.libs/libev.so.4 ${tmp_root}/lib64/
  # Clean up the temp directory
  rm -rf ${tmp_dir}/${libev_tarball} ${tmp_dir}/${libev_name}

  ## Make stud
  stud_name="stud-master"
  stud_tarball="stud.tar.gz"
  stud_location="https://github.com/axsh/stud/archive/master.tar.gz"
  cd ${tmp_dir}

  wget -O ${stud_tarball} ${stud_location}
  tar zxf ${stud_tarball}
  cd ${stud_name}
  make

  cp ${tmp_dir}/${stud_name}/stud ${tmp_root}/usr/bin/
  cp ${tmp_dir}/${stud_name}/upstart/stud.conf ${tmp_root}/etc/init

  mkdir ${tmp_root}/etc/stud

  # Clean up the temp directory
  rm -rf ${tmp_dir}/${stud_tarball} ${tmp_dir}/${stud_name}
  )
}

function setup_wrapper_stunnel() {
  cp ${load_balancer_dir}/etc/init.d/stunnel ${tmp_root}/etc/init.d/stunnel
  cat <<'EOS' | chroot $tmp_root bash -c "cat | bash"
chkconfig stunnel off
ln -s /opt/axsh/wakame-vdc/stunnel /usr/bin/stunnel
EOS
}

function setup_wrapper_stud() {
  # Place any stud setup in here if neccessary
  echo "nuthin'" > /dev/null # Just a useless command to get around the empty function thing
}

function load_balancer_setup() {
  typeset tmp_root="$(cd $1 && pwd)"
  typeset lodev="$2"
  typeset wakame_vdc_dir="$( cd ../../ && pwd )"
  typeset load_balancer_dir="${wakame_vdc_dir}/vmapp/load_balancer"
  typeset wakame_init_path="${wakame_vdc_dir}/tests/image_builder/rhel/6/wakame-init"
  typeset axsh_path="/opt/axsh"
  typeset axsh_dir="${tmp_root}${axsh_path}"
  typeset target_dir="${axsh_dir}/wakame-vdc"
  typeset tmp_dir="${wakame_vdc_dir}/tmp"

  mkdir -p ${axsh_dir}/wakame-vdc/scripts
  mkdir -p ${axsh_dir}/wakame-vdc/amqptools/bin

  cp ${load_balancer_dir}/etc/init/haproxy_updater.conf ${tmp_root}/etc/init/haproxy_updater.conf
  cp ${load_balancer_dir}/scripts/update_haproxy.sh ${target_dir}/scripts/update_haproxy.sh
  cp ${load_balancer_dir}/amqptools/bin/amqpspawn ${target_dir}/amqptools/bin/amqpspawn
  cp ${wakame_init_path} ${tmp_root}/etc/wakame-init
  chmod 755 $tmp_root/etc/wakame-init
  chown 0:0 $tmp_root/etc/wakame-init

  build_wrapper_${ssl_wrapper}

  cat <<EOF > $tmp_root/etc/rc.local
/etc/wakame-init md

. /metadata/user-data
route add -net \${AMQP_SERVER} netmask 255.255.255.255 dev eth1

initctl start haproxy_updater
exit 0
EOF

  init_openvz $tmp_root
  cat <<'EOS' | chroot $tmp_root bash -c "cat | bash"
/sbin/MAKEDEV urandom

# for HAproxy
rpm -ivh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release

# instlall package
distro_pkgs="
 haproxy
"
yum install -y ${distro_pkgs}

# setup chkconfig
chkconfig haproxy off
chkconfig postfix off
chkconfig rsyslog off
chkconfig sshd off
rm -f /etc/haproxy/haproxy.cfg
EOS

  setup_wrapper_${ssl_wrapper}
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
for i in ./${register_image} ; do echo $i; time bash -c "gzip -c $i > $i.gz"; done
rm -f ${output_image}
rm -f ${register_image}
