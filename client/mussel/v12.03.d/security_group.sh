# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $([[ -z "${service_type}" ]] || echo service_type=${service_type} ) \
    $([[ -z "${rule}"         ]] || echo $(strfile_type "rule")       ) \
    $([[ -z "${description}"  ]] || echo description=${description}   ) \
    $([[ -z "${display_name}" ]] || echo display_name=${display_name} ) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
    $([[ -z "${rule}"         ]] || echo $(strfile_type "rule")       ) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
