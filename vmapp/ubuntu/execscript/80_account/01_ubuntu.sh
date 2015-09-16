#!/bin/bash
#
# requires:
#  bash
#
set -e

. ./functions.sh

declare chroot_dir=$1
declare passwd_login=$2
declare user_name=ubuntu

configure_sudo_sudoers ${chroot_dir} ${user_name} NOPASSWD:

if [[ ${passwd_login} = "disabled" ]]; then
    chroot ${chroot_dir} passwd -d ${user_name}
fi
