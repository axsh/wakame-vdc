#!/bin/bash

set -e
set -x

. ./config_s3.env


[ -d ${rpm_dir} ] || mkdir -p ${rpm_dir}

for arch in ${archs}; do
  case ${arch} in
  i*86)   basearch=i386; arch=i686;;
  x86_64) basearch=${arch};;
  esac

  chroot_dir=$(cd ../../ && pwd)/tmp/vmapp_builder/chroot/dest/centos-6_${arch}

  #
  # arch, basearch
  #
  [ -d ${rpm_dir}/${basearch} ] || mkdir -p ${rpm_dir}/${basearch}
  subdirs="
    tmp/wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch}
    root/rpmbuild/RPMS/${arch}
    ${HOME}/rpmbuild/RPMS/${arch}
  "
  for subdir in ${subdirs}; do
    pkg_dir=${chroot_dir}/${subdir}
    bash -c "[ -d ${pkg_dir} ] && rsync -av --exclude=epel-* ${pkg_dir}/*.rpm ${rpm_dir}/${basearch}/ || :"
  done

  #
  # noarch
  #
  [ -d ${rpm_dir}/noarch ] || mkdir -p ${rpm_dir}/noarch
  subdirs="
    root/rpmbuild/RPMS/noarch
    ${HOME}/rpmbuild/RPMS/noarch
  "
  for subdir in ${subdirs}; do
    pkg_dir=${chroot_dir}/${subdir}
    bash -c "[ -d ${pkg_dir} ] && rsync -av --exclude=epel-* ${pkg_dir}/*.rpm ${rpm_dir}/noarch/ || :"
  done
done

# cleanup old wakame-vdc rpms.
find ${rpm_dir} -type f -name "wakame-*" -mtime +5 | sort | while read line; do
  rm -f ${line}
done

# delete non-pair rpms
for i in ${rpm_dir}/*/wakame*.rpm; do
  file=$(basename $i)
  echo ${file%%.el6.*.rpm}
done \
 | sort \
 | uniq -c \
 | sort \
 | awk '$1 == 1 {print $2}' \
 | while read line; do
     # without noarch
     for basearch in ${basearchs}; do
       find pool/vdc/current/${basearch} -type f -name ${line}*
     done
   done | while read target; do
     [ -f ${target} ] || continue
     rm -f ${target}
   done

# create repository metadata files.
(
 cd ${rpm_dir}
 createrepo .
)

# generate index
./gen-index-html.sh > ${rpm_dir}/index.html
