#!/bin/bash
# virtual appliance build script

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

rootsize=${rootsize:-5000}
swapsize=${swapsize:-1000}
base_distro=${base_distro:-centos}
base_distro_number=${base_distro_number:-6}
base_distro_arch=${base_distro_arch:-$(arch)}
# vmbuilder options
ip=${ip:-}
mask=${mask:-}
net=${net:-}
bcast=${bcast:-}
gw=${gw:-}
dns=${dns:-}

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
tmp_dir="${wakame_dir}/tmp/vmapp_builder"

#arch=${arch:-$(arch)}
arch=${base_distro_arch}
case ${arch} in
i*86)   basearch=i386; arch=i686;;
x86_64) basearch=${arch};;
esac

vmapp_names="${vmapp_names:-
 dcmgr
 hva-common
 hva-kvm
 hva-lxc
 hva-openvz
 hva-full
}"

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

# build rhel repository.
repo_dir=${tmp_dir}/repos.d/archives/
[[ -d "${repo_dir}/${basearch}" ]] || mkdir -p "${repo_dir}/${basearch}"

wakame_version="$(egrep ^Version: ${wakame_dir}/rpmbuild/SPECS/wakame-vdc.spec | awk '{print $2}')"
wakame_release="$(${wakame_dir}/rpmbuild/helpers/gen-release-id.sh).*"
wakame_rpms="
 wakame-vdc-${wakame_version}-${wakame_release}
 wakame-vdc-*-${wakame_version}-${wakame_release}
"

# make temp yum repository.
for i in ${wakame_rpms}; do
  for rpm_arch in ${arch} noarch; do
    for f in /root/rpmbuild/RPMS/${rpm_arch}/${i}.${rpm_arch}.rpm; do
      [ -f "${f}" ] && cp "${f}" ${repo_dir}/${basearch}/
    done
  done
done

# 3rd party rpms.
${wakame_dir}/tests/vdc.sh.d/rhel/3rd-party.sh download --vendor-dir=${repo_dir}

# create local repository
(
 cd "${repo_dir}"
 createrepo .
)

echo "Created => ${repo_dir}"


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
rsync -a $tmp_dir/repos.d/archives/${basearch}/openvz.repo \$1/etc/yum.repos.d/openvz.repo

cat <<_REPO_ > \$1/etc/yum.repos.d/wakame-vdc-tmp.repo
[wakame-vdc]
name=Wakame-VDC
baseurl=file:///tmp/repos.d/archives/
enabled=1
gpgcheck=0
_REPO_

chroot \$1 yum ${yum_opts}                   install epel-release -y
chroot \$1 yum ${yum_opts} --enablerepo=epel install wakame-vdc-${vmapp_name}-vmapp-config -y
chroot \$1 rm -f /etc/yum.repos.d/wakame-vdc-tmp.repo
chroot \$1 rm -f /etc/yum.repos.d/openvz.repo

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
  echo umask 022 >> \${devel_home}/.bashrc
}

EOS

rm -rf \$1/tmp/repos.d/
EOF

chmod 755 $tmp_dir/execscript.sh

cd ${tmp_dir}
[ -d vmbuilder ] && {
  cd vmbuilder
  git pull
} || {
  git clone git://github.com/hansode/vmbuilder.git
}

# generate image
cd ${root_dir}
${tmp_dir}/vmbuilder/kvm/rhel/6/vmbuilder.sh \
  --distro-name=${base_distro} \
  --distro-ver=${base_distro_number} \
  --distro-arch=${arch} \
  --raw=./wakame-vdc-${vmapp_name}-vmapp_${base_distro}-${base_distro_number}.${arch}.raw \
  --rootsize=${rootsize} \
  --swapsize=${swapsize} \
  --debug=1 \
  --execscript="$tmp_dir/execscript.sh" \
  --ip=${ip} \
  --mask=${mask} \
  --net=${net} \
  --bcast=${bcast} \
  --gw=${gw} \
  --dns=${dns}

done
