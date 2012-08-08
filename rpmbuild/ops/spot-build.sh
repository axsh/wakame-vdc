#!/bin/bash

set -e
set -x

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

time REPO_URI=$(cd ../../.git && pwd) ./rules clean rpm

[[ -d pool ]] && rm -rf pool || :
time ./createrepo-vdc.sh

release_id=$(../helpers/gen-release-id.sh)
[[ -d ${release_id} ]] && rm -rf ${release_id} || :
rsync -avx pool/vdc/current/ ${release_id}

[[ -f ${release_id}.tar.gz ]] && rm -f ${release_id}.tar.gz
tar zcvpf ${release_id}.tar.gz ${release_id}
ls -la ${release_id}.tar.gz
