# -*-Shell-script-*-
#
# 12.03
#

task_help() {
  cmd_help ${namespace} "index|show|create|xcreate|destroy|poweroff|poweron"
}

task_index() {
  # --state=(running|stopped|terminated|alive)
  if [[ -n "${state}" ]]; then
    xquery="state=${state}"
  fi
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
    display_name=${display_name} \
    protocol=${protocol:-http} \
    port=${balancer_port:-80} \
    instance_port=${instance_port:-80} \
    balance_algorithm=${balance_algorithm:-leastconn} \
    engine=haproxy \
    cookie_name=${cookie_name} \
    private_key=${private_key} \
    public_key=${public_key} \
    engine=haproxy \
    max_connection=${max_connection:-1000} \
    ) \
   ${base_uri}/${1}s.${format}
}

task_xcreate() {
  cmd_xcreate ${namespace}
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}

task_default() {
  cmd_default $*
}
