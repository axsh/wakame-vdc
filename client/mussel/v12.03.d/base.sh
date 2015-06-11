# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/filter/${BASH_SOURCE[0]##*/}

task_index() {
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_destroy() {
  cmd_destroy $*
}

task_xcreate() {
  cmd_xcreate ${namespace}
}

task_default() {
  cmd_default $*
}
