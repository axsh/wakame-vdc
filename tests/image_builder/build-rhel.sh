#!/bin/bash
rootsize=768
swapsize=128
distro_name=centos # [ centos | sl ]
distro_ver=6       # [ 6 | 6.0 | 6.1 | 6.2 | 6.x... ]

set -e
set -x

. ./build_functions-rhel.sh

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >2
  exit 1
}

# generate seed image
# no metadata image (KVM)
run_vmbuilder "${distro_name}-${distro_ver}-kvm-32.raw" "i686"
run_vmbuilder "${distro_name}-${distro_ver}-kvm-64.raw" "x86_64"

loop_mount_image "${distro_name}-${distro_ver}-kvm-32.raw" "kvm_base_setup"
loop_mount_image "${distro_name}-${distro_ver}-kvm-64.raw" "kvm_base_setup"


# metadata server image (KVM)
cp --sparse=auto "${distro_name}-${distro_ver}-kvm-32.raw" "${distro_name}-${distro_ver}-kvm-ms-32.raw"
cp --sparse=auto "${distro_name}-${distro_ver}-kvm-64.raw" "${distro_name}-${distro_ver}-kvm-ms-64.raw"

loop_mount_image "${distro_name}-${distro_ver}-kvm-ms-32.raw" "install_wakame_init" "./rhel/6/wakame-init" "server"
loop_mount_image "${distro_name}-${distro_ver}-kvm-ms-64.raw" "install_wakame_init" "./rhel/6/wakame-init" "server"


# metadata drive image (KVM)
cp --sparse=auto "${distro_name}-${distro_ver}-kvm-32.raw" "${distro_name}-${distro_ver}-kvm-md-32.raw"
cp --sparse=auto "${distro_name}-${distro_ver}-kvm-64.raw" "${distro_name}-${distro_ver}-kvm-md-64.raw"

loop_mount_image "${distro_name}-${distro_ver}-kvm-md-32.raw" "install_wakame_init" "./rhel/6/wakame-init" "drive"
loop_mount_image "${distro_name}-${distro_ver}-kvm-md-64.raw" "install_wakame_init" "./rhel/6/wakame-init" "drive"
