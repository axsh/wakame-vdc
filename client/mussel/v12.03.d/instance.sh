# -*-Shell-script-*-
#
# 12.03
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|create|xcreate|destroy|reboot|stop|start|poweroff|poweron" ;;
index)
  # --state=(running|stopped|terminated|alive)
  xquery="service_type=std"
  if [[ -n "${state}" ]]; then
    xquery="${xquery}\&state=${state}"
  fi
  cmd_index $*
  ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;
create)
  #
  image_id=${image_id:-wmi-lucid5}
  instance_spec_name=${instance_spec_name:-is-small}
  security_groups=${security_groups:-sg-demofgr}
  ssh_key_id=${ssh_key_id:-ssh-demo}
  hypervisor=${hypervisor:-openvz}
  cpu_cores=${cpu_cores:-1}
  memory_size=${memory_size:-1024}
  vifs=${vifs:-\{\}}
  #
  display_name=${display_name:-}
  host_name=${host_name:-}

  call_api -X POST \
   --data-urlencode "image_id=${image_id}" \
   --data-urlencode "instance_spec_name=${instance_spec_name}"  \
   --data-urlencode "security_groups[]=${security_groups}" \
   --data-urlencode "ssh_key_id=${ssh_key_id}" \
   --data-urlencode "hypervisor=${hypervisor}" \
   --data-urlencode "cpu_cores=${cpu_cores}" \
   --data-urlencode "memory_size=${memory_size}" \
   --data-urlencode "display_name=${display_name}" \
   --data-urlencode "host_name=${host_name}" \
   --data-urlencode "vifs=${vifs}" \
   ${base_uri}/${namespace}s.${format}
  ;;
xcreate) cmd_xcreate ${namespace} ;;
backup)
  uuid=$3
  #
  is_public=${is_public:-false}
  is_cacheable=${is_cacheable:-false}
  #
  description=${description:-}

  call_api -X PUT \
   --data-urlencode "description=${description}" \
   --data-urlencode "display_name=${display_name}" \
   --data-urlencode "is_public=${is_public}" \
   --data-urlencode "is_cacheable=${is_cacheable}" \
   ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
  ;;
reboot|stop|start|poweroff|poweron)
  uuid=$3
  call_api -X PUT -d "''" \
   ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
  ;;
*)       cmd_default $* ;;
esac
