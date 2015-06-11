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
  cmd_xcreate ${namespace}
}

task_default() {
  cmd_default $*
}

# piped_task

piped_task_index() {
  case "${mussel_output_format:-""}" in
    id) egrep -- '- :id:' </dev/stdin | awk '{print $3}' ;;
     *) cat ;;
  esac
}

piped_task_destroy() {
  case "${mussel_output_format:-""}" in
    id) tail -n 1 </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

piped_task_create() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

piped_task_update() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}
