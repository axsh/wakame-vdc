# -*-Shell-script-*-
#
# 12.03
#

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
  cmd_xcreate ${1}
}

task_default() {
  cmd_default $*
}
