#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions:     install_wakame_init
#  firefox:       install_firefox
#  google-chrome: install_chrome
#  selenium2:     install_selenium2
#  chromedriver:  install_chromedriver
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh
. ${ROOTPATH}/firefox.sh
. ${ROOTPATH}/google-chrome.sh
. ${ROOTPATH}/chromedriver.sh
. ${ROOTPATH}/selenium2.sh
. ${ROOTPATH}/jenkins-git.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main
configure_hypervisor ${chroot_dir}

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

### others

install_firefox      ${chroot_dir}
install_chrome       ${chroot_dir}
install_chromedriver ${chroot_dir}
install_selenium2    ${chroot_dir}
install_jenkins_git  ${chroot_dir}
