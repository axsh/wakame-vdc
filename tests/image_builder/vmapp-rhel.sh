#!/bin/bash
# virtual appliance build script

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

rootsize=${rootsize:-5000}
swapsize=${swapsize:-1000}
base_distro=${base_distro:-centos}
base_distro_number=${base_distro_number:-6}

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
tmp_dir="${wakame_dir}/tmp/vmapp_builder"
wakame_version="12.03"
wakame_release="1.daily"
arch="x86_64"
wakame_rpms="
 wakame-vdc-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-dcmgr-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
 wakame-vdc-hva-vmapp-config-${wakame_version}-${wakame_release}.${arch}.rpm
"
vmapp_names="
 dcmgr
 hva
"

# . "${root_dir}/build_functions.sh"

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

[[ -d "$tmp_dir" ]] || mkdir -p "$tmp_dir"
for i in $wakame_rpms; do
  rpm_path="${HOME}/rpmbuild/RPMS/x86_64/$i"
  [ -f ${rpm_path} ] || (
    cd ${wakame_dir}
    ./rpmbuild/rules binary
  )
done

# make temp apt repository.
#[[ -d "$tmp_dir/repos.d/archives" ]] && rm -rf   "$tmp_dir/repos.d/archives"
[[ -d "$tmp_dir/repos.d/archives" ]] || mkdir -p "$tmp_dir/repos.d/archives"

for i in $wakame_rpms; do
  cp "${HOME}/rpmbuild/RPMS/${arch}/$i" "$tmp_dir/repos.d/archives"
done

# 3rd party rpms.
${wakame_dir}/tests/vdc.sh.d/rhel/3rd-party.sh download --vendor_dir=$tmp_dir/repos.d/archives

# create local repository
(
 cd "$tmp_dir/repos.d/archives"
 createrepo .
)

yum_opts="--disablerepo='*' --enablerepo=wakame-vdc --enablerepo=openvz-kernel-rhel6 --enablerepo=openvz-utils"
case ${base_distro} in
centos)
  yum_opts="${yum_opts} --enablerepo=base"
  ;;
sl|scientific)
  yum_opts="${yum_opts} --enablerepo=sl"
  ;;
esac

for vmapp_name in ${vmapp_names}; do

cat <<EOF > $tmp_dir/execscript.sh
#!/bin/bash

set -e
set -x

echo "doing execscript.sh: \$1"
rsync -a $tmp_dir/repos.d \$1/tmp/
rsync -a $tmp_dir/repos.d/archives/openvz.repo \$1/etc/yum.repos.d/openvz.repo

cat <<_REPO_ > \$1/etc/yum.repos.d/wakame-vdc-tmp.repo
[wakame-vdc]
name=Wakame-VDC
baseurl=file:///tmp/repos.d/archives/
enabled=1
gpgcheck=0
_REPO_

chroot \$1 yum ${yum_opts}                   install epel-release-6-5 -y
chroot \$1 yum ${yum_opts} --enablerepo=epel install wakame-vdc-${vmapp_name}-vmapp-config -y
chroot \$1 rm -f /etc/yum.repos.d/wakame-vdc-tmp.repo

cat <<'EOS' | chroot \$1 sh -c "cat | sh -ex"
# change root passwd
echo root:root | chpasswd

# instlall package
distro_pkgs="
 vim-minimal
 screen
 git
 make
 sudo
"
yum install -y \${distro_pkgs}

cd /tmp

echo "git clone."
[ -d gist-1108422 ] || git clone git://gist.github.com/1108422.git gist-1108422
cd gist-1108422
pwd

echo "add work user."
./add-work-user.sh
echo "change normal user password"
eval \$(./detect-linux-distribution.sh)
devel_user=\$(echo \${DISTRIB_ID} | tr A-Z a-z)
devel_home=\$(getent passwd \${devel_user} 2>/dev/null | awk -F: '{print \$6}')

echo \${devel_user}:\${devel_user} | chpasswd
egrep -q ^umask \${devel_home}/.bashrc || {
  echo umask 022 >> ${devel_home}/.bashrc
}

EOS

EOF

chmod 755 $tmp_dir/execscript.sh

[ -d ${tmp_dir}/vmbuilder ] || {
  cd ${tmp_dir}
  git clone git://github.com/hansode/vmbuilder.git
}

# generate image
cd ${root_dir}
${tmp_dir}/vmbuilder/kvm/rhel/6/vmbuilder.sh \
  --distro_name=${base_distro} \
  --distro_ver=${base_distro_number} \
  --raw=./wakame-vdc-${vmapp_name}-vmapp_${base_distro}-${base_distro_number}.raw \
  --rootsize=${rootsize} \
  --swapsize=${swapsize} \
  --debug=1 \
  --execscript="$tmp_dir/execscript.sh"

done
