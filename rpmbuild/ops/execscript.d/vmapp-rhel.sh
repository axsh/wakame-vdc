#!/bin/bash

set -e
set -x

arch=${arch:-$(arch)}
case ${arch} in
i*86)   basearch=i386; arch=i686;;
x86_64) basearch=${arch};;
esac

echo "doing execscript.sh: $1"

cat <<EOS | chroot $1 bash -ex
uname -m
cd /tmp
[ -d wakame-vdc ] || git clone git://github.com/axsh/wakame-vdc.git
cd wakame-vdc

./tests/image_builder/vmapp-rhel.sh --base-distro-arch=$(uname -m)
./tests/image_builder/vmapp-rhel.sh --base-distro-arch=$(uname -m) --vmapp-names=example-1box-full
EOS
