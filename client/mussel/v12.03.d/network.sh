# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

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
  $(base_uri)/${namespace}s
}
