# -*-Shell-script-*-
#
# requires:
#  bash
#  cd
#

## system variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
readonly shunit2_file=${abs_dirname}/../../../shunit2

## include files

. ${abs_dirname}/../../../../functions/builder.sh

## group variables

declare chroot_dir=${abs_dirname}/chroot_dir.$$
declare suite_path=${chroot_dir}

## function

function sample_image_ini() {
  cat <<EOS
[vmbuilder]

name          = vanilla

rootsize      = 768
swapsize      = 0

hypervisor    = kvm, lxc, openvz
distro-name   = centos
distro-ver    = 6
arch          = x86_64, i686
sshd-passauth = yes
fstab-type    = label

[wakame-vdc]

metadata-type = md, ms, mcd
EOS
}
