# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/piped/${BASH_SOURCE[0]##*/}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param dc_network) \
    $(add_param description) \
    $(add_param dhcp_range) \
    $(add_param display_name) \
    $(add_param domain_name) \
    $(add_param editable) \
    $(add_param gw) \
    $(add_param ip_assignment) \
    $(add_param network) \
    $(add_param network_mode) \
    $(add_param prefix) \
    $(add_param service_dhcp) \
    $(add_param account_id) \
  ) \
  $(base_uri)/${namespace}s.$(suffix)
}

task_destroy() {

  # usage:
  #   ./mussel.sh network destroy ${uuid}
  local namespace=$1 uuid=$3
  call_api -X DELETE $(base_uri)/${namespace}s/${uuid}
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
    $(add_param dc_network) \
    $(add_param description) \
    $(add_param dhcp_range) \
    $(add_param display_name) \
    $(add_param domain_name) \
    $(add_param editable) \
    $(add_param gw) \
    $(add_param ip_assignment) \
    $(add_param network) \
    $(add_param network_mode) \
    $(add_param prefix) \
    $(add_param service_dhcp) \
    $(add_param account_id) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
