#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#  nginx: install_nginx, configure_nginx_index
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/nginx.sh
. ${ROOTPATH}/fcgiwrap.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main
configure_hypervisor ${chroot_dir}

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_nginx         ${chroot_dir}
configure_nginx_index ${chroot_dir}

install_fcgiwrap              ${chroot_dir}
configure_fcgiwrap_nginx      ${chroot_dir}
configure_fcgiwrap_spawn_fcgi ${chroot_dir}
install_fcgiwrap_envcgi       ${chroot_dir}
