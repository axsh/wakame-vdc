#!/bin/bash

set -e

export LANG=C
export LC_ALL=C

data_path=${data_path:?"data_path needs to be set"}
distro=${distro:?"distro needs to be set"}

# before common

# specified distro
[ -d ${data_path}/${distro} ] || { echo "no such directory: ${data_path}/${distro}"; exit 1; }
(. ${data_path}/${distro}/install.sh)

# after common
(. $VDC_ROOT/tests/vdc.sh.d/install.d/tmp_dirs.sh)
(. $VDC_ROOT/tests/vdc.sh.d/install.d/config_dcmgr.sh)
(. $VDC_ROOT/tests/vdc.sh.d/install.d/config_frontend.sh)
(. $VDC_ROOT/tests/vdc.sh.d/install.d/config_admin.sh)

exit 0
