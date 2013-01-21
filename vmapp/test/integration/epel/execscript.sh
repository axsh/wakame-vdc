#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#  epel:      install_epel
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/epel.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_epel ${chroot_dir}
