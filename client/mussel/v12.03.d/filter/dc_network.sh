# -*-Shell-script-*-
#
#

filter_task_add_offering_modes() {
  case "${mussel_output_format:-""}" in
    minimal) sed 1,1d </dev/stdin | awk '{print $2}' ;;
    *) cat ;;
  esac
}
