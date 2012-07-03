#!/bin/bash

set -e
set -x

archs="x86_64 i686"
basearchs="x86_64 i386"
rpm_dir=pool/vdc/current
s3_repo_uri=s3://dlc.wakame.axsh.jp/packages/rhel/6/

[ -d ${rpm_dir} ] || mkdir -p ${rpm_dir}

for arch in ${archs}; do
  case ${arch} in
  i*86)   basearch=i386; arch=i686;;
  x86_64) basearch=${arch};;
  esac

  [ -d ${rpm_dir}/${basearch} ] || mkdir -p ${rpm_dir}/${basearch}

  chroot_dir=$(cd ../../ && pwd)/tmp/vmapp_builder/chroot/dest/centos-6_${arch}

  subdirs="
    tmp/wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch}
    root/rpmbuild/RPMS/${arch}
  "
  #1  tmp/wakame-vdc/tmp/vmapp_builder/repos.d/archives/${basearch}
  #2  tmp/wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch}
  #3  root/rpmbuild/RPMS/${basearch}

  for subdir in ${subdirs}; do
    pkg_dir=${chroot_dir}/${subdir}
    bash -c "[ -d ${pkg_dir} ] && rsync -av --exclude=epel-* ${pkg_dir}/*.rpm ${rpm_dir}/${basearch}/ || :"
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
     find pool/vdc/current/ -type f -name ${line}*
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

# sync rpms to amazon s3.
s3cmd sync ${rpm_dir} ${s3_repo_uri} --delete-removed --acl-public --check-md5
