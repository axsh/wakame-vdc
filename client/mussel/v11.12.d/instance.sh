# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    image_id=${image_id} \
    instance_spec_id=${instance_spec_id}  \
    ssh_key_id=${ssh_key_id} \
    security_groups[]=${security_groups} \
    ha_enabled=${ha_enabled} \
    network_scheduler=${network_scheduler} \
    $([[ -z "${hostname}"                 ]] || echo hostname=${hostname}) \
    $([[ -z "${host_node_id:-${host_id}}" ]] || echo host_node_id=${host_node_id:-${host_id}}) \
    $(strfile_type "user_data") \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_reboot() {
  cmd_put $*
}

task_stop() {
  cmd_put $*
}

task_start() {
  cmd_put $*
}
