#!/bin/bash

set -e
set -x

LANG=C
LC_ALL=C

abs_path=$(cd $(dirname $0) && pwd)

function update_repo() {
  git pull
}

function setup_chroot_dir() {
  cd ${abs_path}/../../
  [ -d tmp/vmapp_builder/chroot/base ] || mkdir -p tmp/vmapp_builder/chroot/base/
  cd   tmp/vmapp_builder/chroot/base

  distro_name="centos"
  distro_relver="6"
  distro_subver="3"
  distro_ver="${distro_relver}"

  distro="${distro_name}-${distro_ver}"
  distro_detail="${distro_name}-${distro_ver}.${distro_subver}"

  archs="i686 x86_64"
  for arch in ${archs}; do
    [ -f ${distro_detail}_${arch}.tar.gz ] || curl -R -O http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/rootfs-tree/${distro_detail}_${arch}.tar.gz
    [ -d ${distro_detail}_${arch}        ] || sudo tar zxvpf ${distro_detail}_${arch}.tar.gz
    [ -d ${distro}_${arch}               ] || sudo mv ${distro_detail}_${arch} ${distro}_${arch}
  done
}

case $1 in
update_repo)
  $1
  ;;
setup_chroot_dir)
  $1
  ;;
*)
  update_repo
  setup_chroot_dir
  ;;
esac
