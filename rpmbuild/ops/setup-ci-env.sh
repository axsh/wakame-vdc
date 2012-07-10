#!/bin/bash

set -e
set -x

LANG=C
LC_ALL=C


ci_dir=~/work/ci/
[ -d ${ci_dir} ] || mkdir -p ${ci_dir}
cd ${ci_dir}

[ -d wakame-vdc ] || git clone git://github.com/axsh/wakame-vdc.git

cd wakame-vdc
git pull

[ -d tmp/vmapp_builder/chroot/base ] || mkdir -p tmp/vmapp_builder/chroot/base/
cd   tmp/vmapp_builder/chroot/base

distro_name="centos"
distro_relver="6"
distro_subver="2"
distro_ver="${distro_relver}"

distro="${distro_name}-${distro_ver}"
distro_detail="${distro_name}-${distro_ver}.${distro_subver}"

archs="i686 x86_64"
for arch in ${archs}; do
  [ -f ${distro_detail}_${arch}.tar.gz ] || s3cmd get s3://dlc.wakame.axsh.jp/demo/rootfs-tree/${distro_detail}_${arch}.tar.gz
  [ -d ${distro_detail}_${arch}        ] || sudo tar zxvpf ${distro_detail}_${arch}.tar.gz
  [ -d ${distro}_${arch}               ] || sudo mv ${distro_detail}_${arch} ${distro}_${arch}
done
