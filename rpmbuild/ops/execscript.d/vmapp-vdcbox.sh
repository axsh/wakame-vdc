#!/bin/bash
#
#
set -e
set -x

LANG=C

abs_path=$(cd $(dirname $0) && pwd)
mysysconfig=${abs_path}/$(basename $0).config
[ -f ${mysysconfig} ] && . ${mysysconfig}

chroot_dir="${1}"
echo "doing execscript.sh: ${chroot_dir}"

mount --bind /proc ${chroot_dir}/proc
mount --bind /dev  ${chroot_dir}/dev

cat <<EOS | chroot ${chroot_dir} bash -ex
# change root password
echo root:root | chpasswd

# pre-setup
## deploy .repo files
curl -o /etc/yum.repos.d/wakame-vdc.repo -R https://raw.github.com/axsh/wakame-vdc/master/rpmbuild/wakame-vdc.repo
curl -o /etc/yum.repos.d/openvz.repo     -R https://raw.github.com/axsh/wakame-vdc/master/rpmbuild/openvz.repo
## install epel
yum install -y http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-7.noarch.rpm

# install 1box-experiment
yum install -y wakame-vdc-example-1box-experiment-vmapp-config

# set rabbitmq-server cookie
echo PRGXNGPQKGCKEEYIFBVW > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq     /var/lib/rabbitmq/.erlang.cookie
chmod 600                   /var/lib/rabbitmq/.erlang.cookie

# add bridge
/opt/axsh/wakame-vdc/rpmbuild/helpers/setup-bridge-if.sh --brname=${brname} --ifname=${ifname} --ip=${ip} --mask=${mask} --net=${net} --bcast=${bcast} --gw=${gw}

EOS

umount -l ${chroot_dir}/proc
umount -l ${chroot_dir}/dev

cat <<EOS >> ${chroot_dir}/etc/rc.local
[ -x /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh ] && (
  /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh init
  /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh start
) >/var/log/wakame-vdc-vbox.log 2>&1 &
EOS
