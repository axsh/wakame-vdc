#!/bin/bash

set -e
set -x

LANG=C

archs="x86_64 i686"
chroot_dir_fmt="../../tmp/vmapp_builder/chroot/dest/centos-6_%s"

for arch in ${archs}; do
  chroot_dir=$(printf "${chroot_dir_fmt}" ${arch}) 
  echo ${chroot_dir}
  vmapp_src_dir=${chroot_dir}/tmp/wakame-vdc/tests/image_builder

  pool_dir=pool/vmapp/${arch}
  [ -d ${pool_dir} ] || mkdir -d ${pool_dir}

  ls -la ${vmapp_src_dir}/

  for raw_file in ${vmapp_src_dir}/*.raw; do
    [ -f ${raw_file} ] || continue
    echo ... ${raw_file}

    release_id=$(${chroot_dir}/tmp/wakame-vdc/rpmbuild/helpers/gen-release-id.sh)
    dest_file=$(basename ${raw_file})
    dest_file=$(echo ${dest_file} | sed s,${arch}.raw,,)${release_id}.${arch}.raw.gz
    dest_path=${pool_dir}/${dest_file}
    [ -f ${dest_path} ] && continue
    echo ... ${dest_path}
    time gzip -c ${raw_file} > ${dest_path}
  done
done

sync
