#!/bin/bash
#
# RHEL 6.x
#

set -e

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
VDC_ROOT=${VDC_ROOT:?"VDC_ROOT needs to be set"}

# Read dependency information from rpmbuild/SPECS/*.spec.
# % cat rpmbuild/SPECS/*.spec | rpmspec_depends
function rpmspec_depends() {
  # 1. convert space list to line list.
  # 2. remove trailing spaces.
  # 3. remove debian meta variables. i.e. ${shlib:Depends}
  # 4. remove version conditions.
  # 5. remove wakame-vdc packages.
  awk -F: '$1 == "BuildRequires" || $1 == "Requires" { print substr($0, length($1)+2)}' | \
    sed -e 's|\s* \s*|\n|g' | \
    sed -e 's/^[ ]*//g' -e 's/[ ]*$//' | \
    sed -e '/\$/d' | \
    sed  -e 's|[\(].*[\)]||g' | \
    sort | uniq | \
    egrep -v '^wakame-vdc'
}

## Install depend packages
# if someone use different release, they want to modify this conf manually. so check if it exists.

# 3rd party rpms
(
 rpm -qi curl >/dev/null || yum install -y curl

 [ -d $VDC_ROOT/tests/vdc.sh.d/rhel/vendor ] || mkdir -p $VDC_ROOT/tests/vdc.sh.d/rhel/vendor
 cd $VDC_ROOT/tests/vdc.sh.d/rhel/vendor

 [ -f epel-release-6-5.noarch.rpm ] || \
   curl -O http://ftp.riken.go.jp/pub/Linux/fedora/epel/6/i386/epel-release-6-5.noarch.rpm
 [ -f rabbitmq-server-2.6.1-1.noarch.rpm ] || \
   curl -O http://www.rabbitmq.com/releases/rabbitmq-server/v2.6.1/rabbitmq-server-2.6.1-1.noarch.rpm
 [ -f flog-1.8-4.$(arch).rpm ] || \
   curl -O http://cdimage.wakame.jp/packages/rhel/6/flog-1.8-4.$(arch).rpm

 rpm -qi epel-release >/dev/null || \
   yum install -y $VDC_ROOT/tests/vdc.sh.d/rhel/vendor/epel-release-6-5.noarch.rpm
 rpm -qi rabbitmq-server >/dev/null || \
   yum install -y $VDC_ROOT/tests/vdc.sh.d/rhel/vendor/rabbitmq-server-2.6.1-1.noarch.rpm
 rpm -qi flog >/dev/null || \
   yum install -y $VDC_ROOT/tests/vdc.sh.d/rhel/vendor/flog-1.8-4.$(arch).rpm
)

yum update -y
yum upgrade -y
cat ${VDC_ROOT}/rpmbuild/SPECS/*.spec | rpmspec_depends | xargs yum install -y

# rpmbuild/rules installs local ruby binary and bundle install using the binary.
(
  cd $VDC_ROOT
  # skip if build-stamp file exists
  [[ -f build-stamp ]] || {
    ./rpmbuild/rules clean
    ./rpmbuild/rules build
  }

  cd $VDC_ROOT/tests/cucumber
  bundle install --path=vendor/bundle
)

exit 0
