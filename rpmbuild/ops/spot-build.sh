#!/bin/bash
#
# requires:
#   bash
#   rsync, tar, ls
#
set -e
set -x

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

release_id=$(../helpers/gen-release-id.sh)
[[ -f ${release_id}.tar.gz ]] && {
  echo "already built: ${release_id}" >/dev/stderr
  exit 1
}

time REPO_URI=$(cd ../../.git && pwd) ./rules clean rpm

[[ -d pool ]] && rm -rf pool || :
time ./createrepo-vdc.sh

[[ -d ${release_id} ]] && rm -rf ${release_id} || :
rsync -avx pool/vdc/current/ ${release_id}

tar zcvpf ${release_id}.tar.gz ${release_id}
ls -la ${release_id}.tar.gz
