#!/bin/bash

set -e

LANG=C

git_version=$(git log -n 1 --pretty=format:"%h")
#git_date=$(git log -n 1 --pretty=format:"%ad" --date=short | sed 's,-,,g')
git_datetime=$(date --date="$(git log -n 1 --pretty=format:"%ad" --date=iso)" +%Y%m%d%H%M%S)

# * ${git_date}git${git_version}
# - geoclue
# - dbus-c++
# - libpcap tcpdump
# - xorg-x11-drv-nouveau
# - xz

# * git${git_date}
# - ModemManager
# - b43-tools

# * git${git_version}
# - fcoe-target-utils
# - fprintd
# - python-configshell python-rtslib
# - mingw32-sigar sigar

# * ${git_date}git
# - deltarpm
# - mipv6-daemon

echo ${git_datetime}git${git_version}
