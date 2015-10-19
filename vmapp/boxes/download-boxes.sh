#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail

boxes="
     ubuntu-14.04.3-30g.kvm.box
"

function download_file() {
  local filename=${1}
  if [[ -f ${filename}.tmp ]]; then
    # %Y time of last modification, seconds since Epoc
    local lastmod=$(stat -c %Y ${filename}.tmp)
    local now=$(date +%s)
    local ttl=$((60 * 50)) # 1 min

    if [[ "$((${now} - ${lastmod}))" -lt ${ttl} ]]; then
      return 0
    fi

    rm -f ${filename}.tmp
  fi

  # minimal-7.0.1406-x86_64.kvm.box
  local boxes=( ${filename//-/ } )
  # -> minimal 7.0.1406 x86_64.kvm.box
  local versions=( ${boxes[1]//./ } )
  # -> 7 0 1406
  local majorver=${versions[0]}
  # -> 7

  curl -fSkLR --retry 3 --retry-delay 3 http://dlc.wakame.axsh.jp/uservm/ubuntu-minimal-image/current/${filename} -o ${filename}
}

case "${#}" in
  0) ;;
  *) boxes="${@}" ;;
esac

for box in ${boxes}; do
  echo ... ${box}

  download_file ${box}
done
