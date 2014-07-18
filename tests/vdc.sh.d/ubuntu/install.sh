#!/bin/bash
#
# Ubuntu 10.04 LTS
#

set -e

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
VDC_ROOT=${VDC_ROOT:?"VDC_ROOT needs to be set"}

# Read dependency information from debian/control.
# % cat debian/control | debcontrol_depends
function debcontrol_depends() {
  # 1. convert comma list to line list.
  # 2. remove trailing spaces.
  # 3. remove debian meta variables. i.e. ${shlib:Depends}
  # 4. remove version conditions.
  # 5. remove wakame-vdc packages.
  awk -F: '$1 == "Depends" || $1 == "Build-Depends" { print substr($0, length($1)+2)}' | \
    sed -e 's|\s*,\s*|\n|g' | \
    sed -e 's/^[ ]*//g' -e 's/[ ]*$//' | \
    sed -e '/\$/d' | \
    sed  -e 's|[\(].*[\)]||g' | \
    uniq | \
    egrep -v '^wakame-vdc'
}

## Install depend packages

. /etc/lsb-release
case "$DISTRIB_CODENAME" in
lucid)
  # if someone use different release, they want to modify this conf manually. so check if it exists.
  [[ -f /etc/apt/apt.conf.d/99default-release ]] || cp $VDC_ROOT/debian/config/apt/99default-release /etc/apt/apt.conf.d/
  # force overwrite other apt confs.
  cp $VDC_ROOT/debian/config/apt/wakame-vdc.list /etc/apt/sources.list.d/
  cp $VDC_ROOT/debian/config/apt/99wakame-vdc /etc/apt/preferences.d/
  ;;
precise)
  ;;
esac

# debian packages
apt-get update
apt-get -y upgrade
cat ${VDC_ROOT}/debian/control | debcontrol_depends | xargs apt-get -y --force-yes install

# debian/rules installs local ruby binary and bundle install using the binary.
(
  cd $VDC_ROOT
  # skip if build-stamp file exists
  [[ -f build-stamp ]] || {
    ./debian/rules clean
    ./debian/rules build
  }
)

exit 0
