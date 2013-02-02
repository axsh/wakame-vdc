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
  #
  protocol=${protocol:-http}
  balancer_port=${balancer_port:-80}
  instance_port=${instance_port:-80}
  balance_algorithm=${balance_algorithm:-leastconn}
  max_connection=${max_connection:-1000}
  #
  display_name=${display_name:-}
  cookie_name=${cookie_name:-}
  private_key=${private_key:-}
  public_key=${public_key:-}

  call_api -X POST $(urlencode_data \
    display_name=${display_name} \
    protocol=${protocol} \
    port=${balancer_port} \
    instance_port=${instance_port} \
    balance_algorithm=${balance_algorithm} \
    engine=haproxy \
    cookie_name=${cookie_name} \
    private_key=${private_key} \
    public_key=${public_key} \
    engine=haproxy \
    max_connection=${max_connection} \
    ) \
   ${base_uri}/${1}s.${format}
}

task_xcreate() {
  cmd_xcreate ${namespace}
}

task_poweroff() {
  local uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_poweron() {
  local uuid=$3
  call_api -X PUT -d "''" ${base_uri}/${namespace}s/${uuid}/${cmd}.${format}
}

task_default() {
  cmd_default $*
}
