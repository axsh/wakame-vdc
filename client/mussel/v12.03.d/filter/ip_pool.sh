# -*-Shell-script-*-
#
#

filter_task_ip_handles() {
  filter_task_index
}

filter_task_acquire() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:ip_handle_id:' </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}

filter_task_release() {
  filter_task_update
}
