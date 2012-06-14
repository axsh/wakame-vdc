#!/bin/bash
#
# http://wiki.centos.org/HowTos/BuildingKernelModules
# http://supportapj.dell.com/support/edocs/storage/RAID/PERC5/ja/UG/HTML/chapterf.htm
#
# * openvswitch-1.4.1
#
# Requires: gcc
# Requires: rpm-build
# Requires: redhat-rpm-config
# Requires: kernel-devel
# Requires: vzkernel-devel

set -e
set -x

module_name=${module_name:-openvswitch}
module_version=${module_version:-1.4.1}
kpkg_name=${kpkg_name:-vzkernel}

module_dir=/usr/src/${module_name}-${module_version}

kpkg_devel_name=${kpkg_name}-devel
rpm -qi ${kpkg_devel_name} >/dev/null || { echo "not available: ${kpkg_devel_name}" >&2; exit 1; }
kernel_version=$(rpm -qi ${kpkg_devel_name} | egrep ^Version | awk '{print $3}' | sort -r | head -1)
kernel_release=$(rpm -qi ${kpkg_devel_name} | egrep ^Release | awk '{print $3}' | sort -r | head -1)
kernel_variant=${kernel_version}-${kernel_release}
kernel_source_dir=$(rpm -ql ${kpkg_devel_name}-${kernel_variant} | egrep /usr/src/kernels/${kernel_variant} | head -1)
kernel_lib_dir=$(rpm -ql ${kpkg_name}-${kernel_variant} | grep /lib/modules/ | head -1)
kernel_lib_version=$(basename ${kernel_lib_dir})

dkms_opts="-m ${module_name} -v ${module_version}"

[ $UID = 0 ] || {
  echo "You need to be root to perform this command." >&2
  exit 1
}

case $1 in
dump-ver)
  cat <<EOS
kpkg_name=${kpkg_name}
kpkg_devel_name=${kpkg_devel_name}

kernel_version=${kernel_version}
kernel_release=${kernel_release}
kernel_source_dir=${kernel_source_dir}
kernel_lib_dir=${kernel_lib_dir}
kernel_lib_version=${kernel_lib_version}
EOS
  ls -l ${kernel_lib_dir} | grep ${kernel_release}
  ;;
prepare)
  [ -d ${module_dir} ] || {
    cd /tmp
    curl -O http://openvswitch.org/releases/openvswitch-${module_version}.tar.gz
    tar zxvf openvswitch-${module_version}.tar.gz -C $(dirname ${module_dir})
  }

  cd ${module_dir}
  sed "s/__VERSION__/${module_version}/g" debian/dkms.conf.in > ${module_dir}/dkms.conf
  echo Generated: ${module_dir}/dkms.conf
  ;;
add)
  $0 status | grep -w ${module_version} && exit 0 || :
  dkms $1 ${dkms_opts}
  ;;
build)
  $0 status | grep -w added || {
    kpkg_name=${kpkg_name} $0 status | grep -w ${kernel_lib_version} && exit 0
  }
  dkms $1 ${dkms_opts} -k ${kernel_lib_version} --kernelsourcedir=${kernel_source_dir}
  ;;
install)
  $0 status | grep -w ${kernel_lib_version} | grep -w built || exit 0
  dkms $1 ${dkms_opts} -k ${kernel_lib_version}
  ;;
uninstall)
  $0 status | grep -w ${kernel_lib_version} | grep -w installed || exit 0
  dkms $1 ${dkms_opts} -k ${kernel_lib_version}
  ;;
remove)
  $0 status | grep -w built || exit 0
  dkms $1 ${dkms_opts} -k ${kernel_lib_version}
  ;;
test)
  $0 status
  $0 add
  kpkg_name=${kpkg_name} $0 build
  kpkg_name=${kpkg_name} $0 install
  $0 status
  kpkg_name=${kpkg_name} $0 uninstall
  kpkg_name=${kpkg_name} $0 remove
  $0 status
  ;;
status)
  dkms $1 -m ${module_name} -v ${module_version}
  ;;
*)
  echo $0 "[ add | build | install | uninstall | remove | status ]"
  ;;
esac

exit 0
