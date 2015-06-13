# -*-Shell-script-*-
#
#

filter_task_backup() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:image_id:' </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}

filter_task_backup_volume() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:volume_id:' </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}

filter_task_reboot() {
  filter_task_update
}

filter_task_poweroff() {
  filter_task_update
}

filter_task_poweron() {
  filter_task_update
}

filter_task_move() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:instance_id:' </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}
