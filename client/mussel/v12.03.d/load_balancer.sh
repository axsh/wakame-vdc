# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  # --state=(running|stopped|terminated|alive)
  if [[ -n "${state}" ]]; then
    xquery="state=${state}"
  fi
  cmd_index $*
}

task_create() {
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
   $(base_uri)/${namespace}s.$(suffix)
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}
