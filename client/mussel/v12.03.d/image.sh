# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  # --is-public=(true|false|0|1)
  if [[ -n "${is_public}" ]]; then
      xquery="is_public=${is_public}"
  fi
  # --service-type=(std|lb)
  if [[ -n "${service_type}" ]]; then
    xquery="${xquery}\&service_type=${service_type}"
  fi
  cmd_index $*
}
