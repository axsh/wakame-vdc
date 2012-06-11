#!/bin/bash

set -e
set -x


echo "uname -m ...."
uname -m

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

# for tests/repo_builder/build-rhel.sh
./tests/image_builder/vmapp-rhel.sh --base_distro_arch=$(uname -m) --rpm_release=git
EOS

# pwd => /home/scientific/work/repos/git/github.com/wakame-vdc/tests/image_builder

# pickup built rpms
# > wakame-vdc/tmp/vmapp_builder/chroot/dest/centos-6_${arch}/root/rpmbuild/RPMS/
# pickup vmapp raw files
# > wakame-vdc/tmp/vmapp_builder/chroot/dest/centos-6_${arch}/tmp/wakame-vdc/tests/image_builder
# > wakame-vdc/tmp/vmapp_builder/chroot/dest/centos-6_${arch}/tmp/wakame-vdc/tmp/vmapp_builder/repos.d/archives/${basearch}/flog-*.${basearch}.rpm
