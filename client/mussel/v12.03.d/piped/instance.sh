# -*-Shell-script-*-
#
#

piped_task_backup() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:image_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

piped_task_reboot() {
  piped_task_destroy
}

piped_task_poweroff() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:instance_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

piped_task_poweron() {
  piped_task_poweroff
}

piped_task_move() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:instance_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}
