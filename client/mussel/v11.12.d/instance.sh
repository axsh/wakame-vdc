# -*-Shell-script-*-
#
# 11.12
#

task_help() {
  cmd_help ${namespace} "index|show|create|destroy|reboot"
}

task_index() {
  cmd_index $*
}

task_show() {
  cmd_show $*
}

task_destroy() {
  cmd_destroy $*
}

task_create() {
  call_api -X POST $(urlencode_data \
   image_id=${image_id:-wmi-lucid0} \
   instance_spec_id=${instance_spec_id:-is-demospec}  \
   ssh_key_id=${ssh_key_id:-ssh-demo} \
   security_groups[]=${security_groups:-sg-demofgr} \
   ha_enabled=${ha_enabled:-false} \
   network_scheduler=${network_scheduler:-default} \
   $([[ -z "${hostname}" ]] || echo \
   hostname=${hostname}) \
   $([[ -z "${host_node_id:-${host_id}}" ]] || echo \
   host_node_id=${host_node_id:-${host_id}}) \
   $(
     if [[ -f "${user_data}" ]]; then
       echo "user_data@${user_data}"
     elif [[ -n "${user_data}" ]]; then
       echo "user_data=${user_data}"
     fi
   ) \
   ) \
   ${base_uri}/${namespace}s.${format}
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

task_default() {
  cmd_default $*
}
