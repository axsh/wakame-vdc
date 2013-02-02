# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_help() {
  cmd_help ${namespace} "index|show|xcreate|destroy"
}
