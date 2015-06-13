# -*-Shell-script-*-
#
#

# if mussel is called by completion, output always must return raw yaml document.
if [[ "${MUSSEL_CALLER}" == "completion" ]]; then
  return 0
fi

mussel_output_format="${mussel_output_format:-"${MUSSEL_OUTPUT_FORMAT:-""}"}"

filter_task_index() {
  case "${mussel_output_format:-""}" in
    id) egrep -- '- :id:' </dev/stdin | awk '{print $3}' ;;
     *) cat ;;
  esac
}

filter_task_update() {
  case "${mussel_output_format:-""}" in
    id) >/dev/null ;;
     *) cat ;;
  esac
}

filter_task_create() {
  case "${mussel_output_format:-""}" in
    id) egrep '^:id:' </dev/stdin | awk '{print $2}' ;;
     *) cat ;;
  esac
}

filter_task_destroy() {
  filter_task_update
}
