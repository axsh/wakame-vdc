#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#  fcgiwrap:  install_fcgiwrap
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/fcgiwrap.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main

### wakame-init

#install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_fcgiwrap ${chroot_dir}
