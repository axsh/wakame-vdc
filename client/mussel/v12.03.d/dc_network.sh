# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  xquery="name=vnet"
  cmd_index $*
}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param name string) \
    $(add_param offering_network_modes string) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}
