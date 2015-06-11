# -*-Shell-script-*-
#
#

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
  piped_task_create
}
