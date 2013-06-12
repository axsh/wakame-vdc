# -*-Shell-script-*-
#
# requires:
#   bash
#

## retry

function interactive_suspend_test() {
  case "${MUSSEL_FRONTEND}" in
  noninteractive) return 0 ;;
  esac

  echo "press ctrl-D to start tests"
  cat
}
