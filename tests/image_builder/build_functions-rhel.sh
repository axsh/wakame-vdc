#!/bin/bash

set -e

. ./build_functions.sh

function run_vmbuilder() {
  typeset imgpath=$1
  typeset arch=$2 # i686, x86_64
  shift; shift;

  [[ -f $imgpath ]] && rm -f $imgpath

  [ -d vmbuilder ] && {
    cd vmbuilder
    git pull
    cd -
  } || {
    git clone git://github.com/hansode/vmbuilder.git
  }

  # generate image
  echo "Creating image file... $imgpath"
  ./vmbuilder/kvm/rhel/6/vmbuilder.sh \
    --distro_name=centos \
    --distro_ver=${distro_ver:-6} \
    --distro_arch=${arch} \
    --raw=${imgpath} \
    --rootsize=${rootsize} \
    --swapsize=${swapsize} \
    --debug=1
}

# Callback function for loop_mount_image().
#
function kvm_base_setup() {
  typeset tmp_root="$1"
  typeset lodev="$2"

  #Remove SSH host keys
  echo "Removing ssh host keys"
  rm -f $tmp_root/etc/ssh/ssh_host*

  echo "Disabling sshd PasswordAuthentication"
  pwd
  sed -e '/^PasswordAuthentication.*yes/ c\
PasswordAuthentication no
' < $tmp_root/etc/ssh/sshd_config > ./sshd_config.tmp

  egrep '^PasswordAuthentication' ./sshd_config.tmp -q || {
    sed -e '$ a\
PasswordAuthentication no' ./sshd_config.tmp > ./sshd_config
  } && {
    mv ./sshd_config.tmp ./sshd_config
  }

  mv ./sshd_config $tmp_root/etc/ssh/sshd_config
  rm -f ./sshd_config.tmp
}
