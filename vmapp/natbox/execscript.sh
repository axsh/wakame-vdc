#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_epel
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/epel.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

vdc_yum_repo=${vdc_yum_repo:-http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/rhel/6/current/}

## main

###  keepalived

chroot $chroot_dir bash <<EOS

yum install -y kernel-devel-2.6.32-279.el6 rpm-build make gcc openssl-devel popt-devel ipvsadm rpmdevtools net-snmp-devel libnl-devel

rpmdev-setuptree

rpm -ivh http://ftp.redhat.com/pub/redhat/linux/enterprise/6Server/en/os/SRPMS/keepalived-1.2.7-3.el6.src.rpm
rpmbuild -bb /root/rpmbuild/SPECS/keepalived.spec

rpm -ivh /root/rpmbuild/RPMS/*/keepalived*.rpm

chkconfig keepalived on

EOS

### wakame-init

install_epel ${chroot_dir}

chroot $chroot_dir bash <<EOF
cat <<_EOF > /etc/yum.repos.d/wakame-vdc.repo
[wakame-vdc]
name=Wakame-VDC
baseurl=${vdc_yum_repo}
enabled=1
gpgcheck=0
_EOF

yum repolist

yum install -y wakame-vdc

EOF

### openvswitch

chroot $chroot_dir bash <<EOS

yum install -y openvswitch

EOS

exit
