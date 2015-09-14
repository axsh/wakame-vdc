#!/bin/bash
#
# requires:
#  bash
#
set -e

. ./functions.sh

declare chroot_dir=$1
declare user_name=ubuntu

configure_sudo_sudoers ${chroot_dir} ${user_name} NOPASSWD:

