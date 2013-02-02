# -*-Shell-script-*-
#
# 11.12
#

task_help() {
  cmd_help ${namespace} "index|show"
}

task_index() {
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_default() {
  cmd_default $*
}
