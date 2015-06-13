# -*-Shell-script-*-
#
#

filter_task_expire_at() {
  case "${mussel_output_format:-""}" in
    minimal) egrep '^:expires_at:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}
