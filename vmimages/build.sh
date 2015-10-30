#!/bin/bash

set -e

function abort() {
  local msg=$1
  echo "$msg" >&2
  exit 1
}

function qemu_build() {
  echo "Start to build $(basename $(pwd))"
  qemu-build qemu-build.conf
}

export PATH="$PATH:$(pwd)/bin"

TARGET_DIR=${1:?"ERROR: Unknown target"}

if [[ ! -d $TARGET_DIR ]]; then
  abort "ERROR: Can't find target: $TARGET_DIR"
fi

( 
  cd $TARGET_DIR
  qemu_build
)
