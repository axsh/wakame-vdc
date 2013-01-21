# -*-Shell-script-*-
#
# requires:
#  bash
#  cd
#

## system variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
readonly shunit2_file=${abs_dirname}/../../../shunit2

## include files

. ${abs_dirname}/../../../../build.sh.d/amqptools.sh

## group variables

declare chroot_dir=${abs_dirname}/chroot_dir.$$
