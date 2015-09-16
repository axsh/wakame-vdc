#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
box_path=${1}

[[ -n "${box_path}" ]] || { echo "File not found." >&2; exit 1; }

time tar zxvf ${box_path}
time sync
