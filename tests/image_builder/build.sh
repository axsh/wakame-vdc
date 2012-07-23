#!/bin/bash
rootsize=500
swapsize=128

set -e
set -x

. ./build_functions.sh

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >2
  exit 1
}

# generate seed image
[ -f ubuntu-lucid-32.raw ] || run_vmbuilder "ubuntu-lucid-32.raw" "i386"
[ -f ubuntu-lucid-64.raw ] || run_vmbuilder "ubuntu-lucid-64.raw" "amd64"

# no metadata image (KVM)
cp --sparse=auto "ubuntu-lucid-32.raw" "ubuntu-lucid-kvm-32.raw"
cp --sparse=auto "ubuntu-lucid-64.raw" "ubuntu-lucid-kvm-64.raw"

loop_mount_image "ubuntu-lucid-kvm-32.raw" "kvm_base_setup"
loop_mount_image "ubuntu-lucid-kvm-64.raw" "kvm_base_setup"


# metadata server image (KVM)
cp --sparse=auto "ubuntu-lucid-kvm-32.raw" "ubuntu-lucid-kvm-ms-32.raw"
cp --sparse=auto "ubuntu-lucid-kvm-64.raw" "ubuntu-lucid-kvm-ms-64.raw"

loop_mount_image "ubuntu-lucid-kvm-ms-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"
loop_mount_image "ubuntu-lucid-kvm-ms-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"

# metadata drive image (KVM)
cp --sparse=auto "ubuntu-lucid-kvm-32.raw" "ubuntu-lucid-kvm-md-32.raw"
cp --sparse=auto "ubuntu-lucid-kvm-64.raw" "ubuntu-lucid-kvm-md-64.raw"

loop_mount_image "ubuntu-lucid-kvm-md-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
loop_mount_image "ubuntu-lucid-kvm-md-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"

exit 0

# no metadata image (LXC)
cp --sparse=auto "ubuntu-lucid-32.raw" "ubuntu-lucid-lxc-32.raw"
cp --sparse=auto "ubuntu-lucid-64.raw" "ubuntu-lucid-lxc-64.raw"

loop_mount_image "ubuntu-lucid-lxc-32.raw" "lxc_base_setup"
loop_mount_image "ubuntu-lucid-lxc-64.raw" "lxc_base_setup"

# metadata server image (LXC)
cp --sparse=auto "ubuntu-lucid-lxc-32.raw" "ubuntu-lucid-lxc-ms-32.raw"
cp --sparse=auto "ubuntu-lucid-lxc-64.raw" "ubuntu-lucid-lxc-ms-64.raw"

loop_mount_image "ubuntu-lucid-lxc-ms-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"
loop_mount_image "ubuntu-lucid-lxc-ms-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "server"

# metadata drive image (LXC)
cp --sparse=auto "ubuntu-lucid-lxc-32.raw" "ubuntu-lucid-lxc-md-32.raw"
cp --sparse=auto "ubuntu-lucid-lxc-64.raw" "ubuntu-lucid-lxc-md-64.raw"

loop_mount_image "ubuntu-lucid-lxc-md-32.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
loop_mount_image "ubuntu-lucid-lxc-md-64.raw" "install_wakame_init" "./ubuntu/10.04/wakame-init" "drive"
