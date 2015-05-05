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

# chroot directory is given in first argument.
declare chroot_dir=$1

## main
configure_hypervisor ${chroot_dir}

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

## custom build procedure

chroot $1 $SHELL -ex <<'EOS'
  # pre-setup
  yum install -y --disablerepo=updates git
  yum install -y --disablerepo=updates mysql-server

  # service configuration
  svcs="
   mysqld
  "
  for svc in ${svcs}; do
    chkconfig --list ${svc}
    chkconfig ${svc} on
    chkconfig --list ${svc}
  done

  # cleanup
  history -c
EOS

## user-data script

chroot $1 $SHELL -ex <<'EOS'
  echo '[ -f /metadata/user-data ] && . /metadata/user-data' >> /etc/rc.d/rc.local
EOS
