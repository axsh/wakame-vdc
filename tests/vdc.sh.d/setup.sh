#!/bin/bash

set -e

export LANG=C
export LC_ALL=C

data_path=${data_path:?"data_path needs to be set"}
distro=${distro:?"distro needs to be set"}

# before common
(. $VDC_ROOT/tests/vdc.sh.d/setup.d/hostname.sh)

# specified distro
[ -d ${data_path}/${distro} ] || { echo "no such directory: ${data_path}/${distro}"; exit 1; }
(. ${data_path}/${distro}/setup.sh)

# after common

exit 0
