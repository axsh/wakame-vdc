# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_show_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X GET $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}

task_attach_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X POST $(urlencode_data \
    $(add_param ip_handle_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}

task_detach_external_ip() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X DELETE $(urlencode_data \
    $(add_param ip_handle_id string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/external_ip.$(suffix)
}
