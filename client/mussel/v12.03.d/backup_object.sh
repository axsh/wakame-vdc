# -*-Shell-script-*-
#
# 12.03
#

task_help() {
  cmd_help ${namespace} "index|show|xcreate|destroy"
}

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
