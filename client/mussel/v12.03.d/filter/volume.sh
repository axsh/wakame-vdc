# -*-Shell-script-*-
#
#

filter_task_backup() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:volume_id:' </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}

filter_task_attach() {
  filter_task_update
}

filter_task_detach() {
  filter_task_update
}
