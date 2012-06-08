#!/bin/bash

set -e
set -x

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=${key##--}
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      args="${args} ${arg}"
      ;;
  esac
  shift
done

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../../"
tmp_dir="${wakame_dir}/tmp/vmapp_builder"
wakame_version="$(egrep ^Version: ${wakame_dir}/rpmbuild/SPECS/wakame-vdc.spec | awk '{print $2}')"
wakame_release="$(egrep ^Release: ${wakame_dir}/rpmbuild/SPECS/wakame-vdc.spec | awk '{print $2}' | sed 's,%{.*},*,')"

repo_dir=${repo_dir:-${root_dir}/repo.d}

arch=${arch:-$(arch)}
case ${arch} in
i*86)   basearch=i386; arch=i686;;
x86_64) basearch=${arch};;
esac

wakame_rpms="
 wakame-vdc-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-debug-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-dcmgr-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-common-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-kvm-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-lxc-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-openvz-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-full-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
"

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

[[ -d "$tmp_dir" ]] || mkdir -p "$tmp_dir"
for i in $wakame_rpms; do
  rpm_path="${HOME}/rpmbuild/RPMS/${arch}/$i"
  [ -f ${rpm_path} ] || (
    cd ${wakame_dir}
    ./rpmbuild/rules binary
  )
done

# make temp yum repository.
[[ -d "$tmp_dir/repos.d/archives/${basearch}" ]] || mkdir -p "$tmp_dir/repos.d/archives/${basearch}"
[[ -d "${repo_dir}/${basearch}" ]] || mkdir -p "${repo_dir}/${basearch}"

for i in $wakame_rpms; do
  cp ${HOME}/rpmbuild/RPMS/${arch}/$i ${repo_dir}/${basearch}
done

# 3rd party rpms.
${wakame_dir}/tests/vdc.sh.d/rhel/3rd-party.sh download --vendor_dir=$tmp_dir/repos.d/archives
rsync -a $tmp_dir/repos.d/archives/${basearch}/*.rpm ${repo_dir}/${basearch}/

# create local repository
(
 cd "${repo_dir}"
 createrepo .
)

echo "Created => ${repo_dir}"
