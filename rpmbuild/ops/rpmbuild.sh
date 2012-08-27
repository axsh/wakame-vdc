#!/bin/bash
# rpm build script

PATH=/bin:/usr/bin:/sbin:/usr/sbin

set -e
set -x

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      args="${args} ${arg}"
      ;;
  esac
  shift
done

base_distro=${base_distro:-centos}
base_distro_number=${base_distro_number:-6}
base_distro_arch=${base_distro_arch:-$(arch)}
repo_uri=${repo_uri:-git://github.com/axsh/wakame-vdc.git}

execscript=${execscript:-}
cacheback=${cacheback:-1}

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
tmp_dir="${wakame_dir}/tmp/vmapp_builder"

#arch=${arch:-$(arch)}
arch=${base_distro_arch}
case ${arch} in
i*86)   basearch=i386; arch=i686;;
x86_64) basearch=${arch};;
esac

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

[[ -d "$tmp_dir" ]] || mkdir -p "$tmp_dir"

cd ${tmp_dir}
[ -d vmbuilder ] && {
  cd vmbuilder
  git pull
} || {
  git clone git://github.com/hansode/vmbuilder.git
}

base_chroot_dir=${tmp_dir}/chroot/base/${base_distro}-${base_distro_number}_${base_distro_arch}
dest_chroot_dir=${tmp_dir}/chroot/dest/${base_distro}-${base_distro_number}_${base_distro_arch}

[ -d ${base_chroot_dir} ] || {
  ${tmp_dir}/vmbuilder/kvm/rhel/6/build-rootfs-tree.sh \
   --distro_name=${base_distro} \
   --distro_ver=${base_distro_number} \
   --distro_arch=${base_distro_arch} \
   --chroot_dir=${base_chroot_dir} \
   --batch=1 \
   --debug=1
  sync
}

cd ${root_dir}
[ -d ${dest_chroot_dir} ] && {
  echo already exists: ${dest_chroot_dir} >&2
} || {
  mkdir -p ${dest_chroot_dir}
}
rsync -ax --delete ${base_chroot_dir}/ ${dest_chroot_dir}/
sync

# for local repository
case ${repo_uri} in
file:///*|/*)
  local_path=${repo_uri##file://}
  [ -d ${local_path} ] && {
    [ -d ${dest_chroot_dir}/${local_path} ] || mkdir -p ${dest_chroot_dir}/${local_path}
    rsync -avx ${local_path} ${dest_chroot_dir}/${local_path}
  }
  ;;
*)
  ;;
esac

### after-deploy
case "${after_deploy}" in
use-s3snap)
  # skip deploying openvz.repo at "3rd-party.sh download"
  cd ${dest_chroot_dir}/tmp

  curl -O -R http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/snap/rhel/6/current/wakame-vdc-snap.repo
  rsync -a ./wakame-vdc-snap.repo ${dest_chroot_dir}/etc/yum.repos.d/openvz.repo

  [ -d wakame-vdc ] || git clone ${repo_uri} wakame-vdc
  [ -d wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch} ] || mkdir -p wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch}
  rsync -a ./wakame-vdc-snap.repo wakame-vdc/tests/vdc.sh.d/rhel/vendor/${basearch}/openvz.repo
  ;;
*)
  ;;
esac
### after-deploy

for mount_target in proc dev; do
  mount | grep ${dest_chroot_dir}/${mount_target} || mount --bind /${mount_target} ${dest_chroot_dir}/${mount_target}
done

yum_opts="--disablerepo='*'"
# --enablerepo=wakame-vdc --enablerepo=openvz-kernel-rhel6 --enablerepo=openvz-utils"
case ${base_distro} in
centos)
  yum_opts="${yum_opts} --enablerepo=base"
  ;;
sl|scientific)
  yum_opts="${yum_opts} --enablerepo=sl"
  ;;
esac

# run in chrooted env.
cat <<EOS | setarch ${arch} chroot ${dest_chroot_dir}/  bash -ex
uname -m

[[ -f /etc/yum.conf ]] && sed -i "s,^keepcache=.*,keepcache=1," /etc/yum.conf

yum ${yum_opts} update -y
yum ${yum_opts} install -y git make sudo

cd /tmp
[ -d wakame-vdc ] || git clone ${repo_uri} wakame-vdc
cd wakame-vdc

sleep 3
./tests/vdc.sh install::rhel
sync

sleep 3
VDC_BUILD_ID=${build_id} VDC_REPO_URI=${repo_uri} ./rpmbuild/rules binary-snap
sync
EOS

[ -z "${execscript}" ] || {
  [ -x "${execscript}" ] && {
    setarch ${arch} ${execscript} ${dest_chroot_dir}
  } || :
}

for mount_target in proc dev; do
  mount | grep ${dest_chroot_dir}/${mount_target} || {
    umount -l ${dest_chroot_dir}/${mount_target}
  }
done

[[ -z "${cacheback}" ]] || {
  rsync -ax ${dest_chroot_dir}/var/cache/yum/ ${base_chroot_dir}/var/cache/yum/
}

echo "Complete!!"
