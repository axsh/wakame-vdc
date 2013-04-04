# -*-Shell-script-*-
#
# description:
#  frontend common file
#
# requires:
#  bash, pwd
#
# imports:
#  utils:
#  wakame-init:
#

. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/hypervisor.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/wakame-init.sh
