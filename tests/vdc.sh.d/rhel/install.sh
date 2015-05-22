#!/bin/bash
#
# RHEL 6.x
#

set -e

export LANG=C
export LC_ALL=C
VDC_ROOT=${VDC_ROOT:?"VDC_ROOT needs to be set"}

# Read dependency information from rpmbuild/SPECS/*.spec.
# % cat rpmbuild/SPECS/*.spec | rpmspec_depends
function rpmspec_depends() {
  # 0. remove redhat meta variables.
  # 1. convert space list to line list.
  # 2. remove trailing spaces.
  # 3. remove debian meta variables. i.e. ${shlib:Depends}
  # 4. remove version conditions.
  # 5. remove wakame-vdc packages.
  awk -F: '$1 == "BuildRequires" || $1 == "Requires" { print substr($0, length($1)+2)}' | \
    egrep -v '%|=' |\
    sed -e 's|\s* \s*|\n|g' | \
    sed -e 's/^[ ]*//g' -e 's/[ ]*$//' | \
    sed -e '/\$/d' | \
    sed  -e 's|[\(].*[\)]||g' | \
    sort | uniq | \
    egrep -v '^wakame-vdc'
}

# disable SELinux
[[ "$(getenforce)" == "Disabled" ]] || setenforce 0

yum install -y curl yum-plugin-versionlock

# Setup private Ruby binary using rvm

RUBYVER=${RUBYVER:-2.1.0}
if !(which ruby > /dev/null); then
  if ! type -t rvm > /dev/null; then
    curl -sSL https://get.rvm.io | bash -s stable
  fi
  . "$HOME/.rvm/scripts/rvm" || . /usr/local/rvm/scripts/rvm
  if ! rvm use $RUBYVER; then
     CFLAGS="-O0 -g" rvm install $RUBYVER --disable-binary
     rvm use $RUBYVER
  fi
  if ! gem search -i bundler > /dev/null; then
    gem install bundler
  fi
fi

# if someone use different release, they want to modify this conf manually. so check if it exists.

# 3rd party rpms
${VDC_ROOT}/tests/vdc.sh.d/rhel/3rd-party.sh download
${VDC_ROOT}/tests/vdc.sh.d/rhel/3rd-party.sh install

#yum update -y
#yum upgrade -y
cat ${VDC_ROOT}/rpmbuild/SPECS/*.spec | rpmspec_depends | xargs yum install --disablerepo='openvz*' -y
#cat ${VDC_ROOT}/rpmbuild/SPECS/*.spec | rpmspec_depends | xargs yum install -y

# rpmbuild/rules installs local ruby binary and bundle install using the binary.
(
  cd $VDC_ROOT
  #./rpmbuild/rules clean
  ./rpmbuild/rules bundle-install
)

exit 0
