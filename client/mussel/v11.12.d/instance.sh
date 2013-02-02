# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|destroy|reboot" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;

create)
  image_id=${image_id:-wmi-lucid0}
  instance_spec_id=${instance_spec_id:-is-demospec}
  ssh_key_id=${ssh_key_id:-ssh-demo}
  security_groups=${security_groups:-sg-demofgr}
  hostname=${hostname:-}
  ha_enabled=${ha_enabled:-false}
  network_scheduler=${network_scheduler:-default}
  host_id=${host_id}
  host_node_id=${host_node_id:-${host_id}}
  user_data=${user_data:-}

  call_api -X POST $(urlencode_data \
   image_id=${image_id} \
   instance_spec_id=${instance_spec_id}  \
   ssh_key_id=${ssh_key_id} \
   security_groups[]=${security_groups} \
   ha_enabled=${ha_enabled} \
   network_scheduler=${network_scheduler} \
   $([[ -z "${hostname}" ]] || echo \
   hostname=${hostname}) \
   $([[ -z "${host_node_id}" ]] || echo \
   host_node_id=${host_node_id}) \
   $(
     if [[ -f "${user_data}" ]]; then
       echo "user_data@${user_data}"
     elif [[ -n "${user_data}" ]]; then
       echo "user_data=${user_data}"
     fi
   ) \
   ) \
   ${base_uri}/${namespace}s.${format}
  ;;
reboot|stop|start)
  uuid=$3
  call_api -X PUT -d "''" \
   ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
  ;;
*)       cmd_default $* ;;
esac
