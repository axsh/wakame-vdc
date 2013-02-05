#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/epel.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

vdc_yum_repo=${vdc_yum_repo:?ERROR: vdc_yum_repo is unset}

## main

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

rm -f /etc/yum.repos.d/wakame-vdc.repo

EOF

exit
