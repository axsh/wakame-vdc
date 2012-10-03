#!/bin/bash
rootsize=500
swapsize=128

set -e
set -x

. ./build_functions.sh

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >&2
  exit 1
}

# generate seed image
[ -f ubuntu-lucid-32-secgtest.raw ] || run_vmbuilder_secgtest "ubuntu-lucid-32-secgtest.raw" "i386"

loop_mount_image "ubuntu-lucid-32-secgtest.raw" "kvm_base_setup"

cp ./ubuntu/10.04/wakame-init /tmp/wakame-init
echo '/opt/echo_server.rb `get_userdata` &' >> /tmp/wakame-init
loop_mount_image "ubuntu-lucid-32-secgtest.raw" "install_wakame_init" "/tmp/wakame-init" "drive"
rm /tmp/wakame-init

loop_mount_image "ubuntu-lucid-32-secgtest.raw" "install_secg_test_scripts" "./secgtest/opt"

exit 0
