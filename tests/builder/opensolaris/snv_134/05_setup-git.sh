#!/bin/sh

git_ver=1.7.5

cd /tmp
[ -f git-${git_ver}.tar.bz2 ] || {
  wget http://kernel.org/pub/software/scm/git/git-${git_ver}.tar.bz2
}

[ -d git-${git_ver} ] || {
  tar xf git-${git_ver}.tar.bz2
}

cd git-${git_ver}

[ -f Makefile ] || {
  ./configure --prefix=/opt/git-${git_ver} --with-openssl --with-curl
}
gmake all

[ -d /opt/git-${git_ver}/bin ] || {
  mkdir -p /opt/git-${git_ver}/bin
}

[ -L /opt/git ] || {
  ln -s /opt/git-${git_ver} /opt/git
}

find . -type f -perm 755 -name "git*" | egrep ^\./git | while read line; do
  cp -p ${line} /opt/git-${git_ver}/bin/$(basename ${line})
done

rofiles="
  git-sh-setup
"

for rofile in ${rofiles}; do
  cp -p ${rofile} /opt/git-${git_ver}/bin/${rofile}
  chmod a+x /opt/git-${git_ver}/bin/${rofile}
done

exit 0
