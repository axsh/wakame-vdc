#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

chroot ${chroot_dir} $SHELL -ex <<EOS
  wget http://dlc.wakame.axsh.jp/packages/ubuntu/14.04/current/wakame-init_15.03-1_all.deb
  dpkg -i wakame-init_15.03-1_all.deb
EOS

