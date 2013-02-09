# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $([[ -z "${ha_enabled}"               ]] || echo ha_enabled=${ha_enabled}                ) \
    $([[ -z "${host_node_id:-${host_id}}" ]] || echo host_node_id=${host_node_id:-${host_id}}) \
    $([[ -z "${hostname}"                 ]] || echo hostname=${hostname}                    ) \
    $([[ -z "${image_id}"                 ]] || echo image_id=${image_id}                    ) \
    $([[ -z "${instance_spec_id}"         ]] || echo instance_spec_id=${instance_spec_id}    ) \
    $([[ -z "${network_scheduler}"        ]] || echo network_scheduler=${network_scheduler}  ) \
    $([[ -z "${security_groups}"          ]] || echo security_groups[]=${security_groups}    ) \
    $([[ -z "${ssh_key_id}"               ]] || echo ssh_key_id=${ssh_key_id}                ) \
    $([[ -z "${user_data}"                ]] || strfile_type "user_data"                     ) \
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
