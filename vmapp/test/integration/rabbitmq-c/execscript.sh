#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#  rabbitmq-c:install_rabbitmq_c
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/rabbitmq-c.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_rabbitmq_c ${chroot_dir}
