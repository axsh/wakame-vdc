#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#  jre6:      install_jre6
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/jre6.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_jre6 ${chroot_dir}
