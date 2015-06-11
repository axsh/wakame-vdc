# -*-Shell-script-*-
#
#

piped_task_reboot() {
  piped_task_destroy
}

piped_task_poweroff() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:load_balancer_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

piped_task_poweron() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:load_balancer_id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}
