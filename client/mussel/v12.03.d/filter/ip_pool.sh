# -*-Shell-script-*-
#
#

filter_task_ip_handles() {
  filter_task_update
}

filter_task_acquire() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:ipv4:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

filter_task_release() {
  filter_task_update
}
