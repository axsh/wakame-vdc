#!/bin/bash
#
# description:
#  VM builder for Wakame-vDC
#
# requires:
#  bash
#  pwd
#
# import:
#  builder: build_vm
#
# memo:
#
set -e

### read-only variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)

## include files

. ${abs_dirname}/functions/builder.sh

## variables

###  environment variables

export LANG=C
export LC_ALL=C
export ROOTPATH="${abs_dirname}/${BASH_SOURCE[0]##*/}.d"

### shell variables

declare suite_path=$1

## main

build_vm ${suite_path}
