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
yum install -y http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release

# install 1box-experiment
yum install -y wakame-vdc-example-1box-experiment-vmapp-config

# set rabbitmq-server cookie
echo PRGXNGPQKGCKEEYIFBVW > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq     /var/lib/rabbitmq/.erlang.cookie
chmod 600                   /var/lib/rabbitmq/.erlang.cookie

# add bridge
/opt/axsh/wakame-vdc/rpmbuild/helpers/setup-bridge-if.sh --brname=${brname0} --ifname=${ifname0} --ip=${ip0} --mask=${mask0} --net=${net0} --bcast=${bcast0} --gw=${gw0}
/opt/axsh/wakame-vdc/rpmbuild/helpers/setup-bridge-if.sh --brname=${brname1} --ifname=${ifname1} --ip=${ip1} --mask=${mask1} --net=${net1} --bcast=${bcast1} --gw=${gw1}

EOS

cat <<'EOS' >> ${chroot_dir}/etc/rc.local
[ -f /var/log/wakame-vdc-vbox.log ] && \mv /var/log/wakame-vdc-vbox.log /var/log/wakame-vdc-vbox.log.1
[ -x /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh ] && (
  echo "### self-init-vdcbox.sh ###"
  date; start_at=$(date +%s)
  time /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh init
  time /opt/axsh/wakame-vdc/rpmbuild/helpers/self-init-vdcbox.sh start
  date; end_at=$(date +%s)
  echo  "[total] $((${end_at} - ${start_at}))"
) >/var/log/wakame-vdc-vbox.log 2>&1 &
EOS

umount -l ${chroot_dir}/proc
umount -l ${chroot_dir}/dev
