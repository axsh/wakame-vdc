# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  local name=$3
  [[ -n "${name}" ]] || { echo "${namespace} ${cmd} NAME" >&2; return 1; }

  call_api -X POST $(urlencode_data \
    name=${name} \
   ) \
   ${DCMGR_BASE_URI}/${namespace}s.${format}
}
