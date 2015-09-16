#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

[[ -f ./metadata/vmspec.conf ]]
.     ./metadata/vmspec.conf

sudo /bin/bash -e <<EOS
  if [[ -f ./prebuild.sh ]]; then
    ./prebuild.sh ${box_path}
  fi

  ./unpack-box.sh ${box_path}
  passwd_login=${passwd_login} raw=${raw} ./kemumaki-init.sh
EOS
