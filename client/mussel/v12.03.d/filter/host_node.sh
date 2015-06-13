# -*-Shell-script-*-
#
#

filter_task_evacuate() {
  # raw:
  #> ---
  #> :scheduled: []
  #> :failed: []
  #
  # filterd:
  #> :scheduled: []
  #> :failed: []
  case "${mussel_output_format:-""}" in
    minimal) sed 1,1d </dev/stdin ;;
    *) cat ;;
  esac
}
