#!/bin/bash

set -x

abs_path=$(cd $(dirname $0) && pwd)
wakame_root=$(cd ${abs_path}/../../ && pwd)
log_dir=${abs_path}/logs

# make vmapp
# -> make vmapp{32,64}
#    -> tests/image_builder/rpmbuild.sh --execscript=./execscript.d/vmapp-rhel.sh --base-distro-arch={x86_64,i686}
#       -> build-rootfs-tree.sh ...
#       -> ./tests/vdc.sh install::rhel
#          -> ./tests/vdc.sh.d/rhel/install.sh
#             -> ./tests/vdc.sh.d/rhel/3rd-party.sh download
#             -> ./tests/vdc.sh.d/rhel/3rd-party.sh install
#             -> yum install --disablerepo='openvz*' -y
#             -> yum install -y
#          -> ./tests/vdc.sh.d/rhel/setup.sh
#       -> ./rpmbuild/rules binary-snap
#       -> tests/image_builder/vmapp-rhel.sh --base-distro-arch=$(uname -m) --rpm-release=gi
#           -> chroot [dir] yum install wakame-vdc-***

[ -d ${log_dir} ] || mkdir -p ${log_dir}

(
 date

 # build vmapp & rpm
 cd ${wakame_root}/tests/image_builder/
 for arch in x86_64 i686; do
   time ./rpmbuild.sh --execscript=./execscript.d/vmapp-rhel.sh --base-distro-arch=${arch}
 done

 cd ${abs_path}

 # upload rpms to s3
 time ./build-s3-vdc.sh 2>&1
 date
 # upload vmapps to s3
 time ./build-s3-vmapp.sh 2>&1
 date
) 2>&1 | tee ${log_dir}/build.log.`date +%Y%m%d-%s` 2>&1
