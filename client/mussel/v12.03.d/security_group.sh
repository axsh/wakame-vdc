# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    service_type=${service_type:-std} \
    $(
      if [[ -f "${rule}" ]]; then
        echo rule@${rule}
      else
        echo rule=${rule:-}
      fi
    ) \
    description=${description:-} \
    display_name=${display_name:-} \
    ) \
   ${base_uri}/${1}s.${format}
}
