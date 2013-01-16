# -*-Shell-script-*-
#
# requires:
#  bash
#  cd
#

## system variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
readonly shunit2_file=${abs_dirname}/../../shunit2

## include files

## group variables

declare builder_path=${abs_dirname}/../../../build.sh
declare suite_path=${abs_dirname}

## functions

function cleanup_vm() {
  rm -f ${suite_path}/*.raw
  rm -f ${suite_path}/*.tar.gz
}
