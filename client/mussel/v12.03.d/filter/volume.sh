# -*-Shell-script-*-
#
#

filter_backup() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:volume_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

filter_attach() {
  filter_task_update
}

filter_detach() {
  filter_task_update
}
