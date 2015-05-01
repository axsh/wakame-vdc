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

  # installation
  addpkgs="
   hold-releasever.hold-baseurl
   jenkins.master
   hubot.common
   jenkins.plugin.rbenv
   httpd
   rpmbuild
  "

  if [[ -z "$(echo ${addpkgs})" ]]; then
    exit 0
  fi

  deploy_to=/var/tmp/buildbook-rhel6

  if ! [[ -d "${deploy_to}" ]]; then
    git clone https://github.com/wakameci/buildbook-rhel6.git ${deploy_to}
  fi

  cd ${deploy_to}
  git checkout master
  git pull

  ./run-book.sh ${addpkgs}

  # service configuration
  svcs="
   jenkins
   httpd
  "
  for svc in ${svcs}; do
    chkconfig --list ${svc}
    chkconfig ${svc} on
    chkconfig --list ${svc}
  done

  # cleanup
  history -c
EOS
