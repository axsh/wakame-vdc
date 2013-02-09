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
    $([[ -z "${balance_algorithm}" ]] || echo balance_algorithm=${balance_algorithm} ) \
    $([[ -z "${cookie_name}"       ]] || echo cookie_name=${cookie_name}             ) \
    $([[ -z "${display_name}"      ]] || echo display_name=${display_name}           ) \
    $([[ -z "${engine}"            ]] || echo engine=${engine}                       ) \
    $([[ -z "${instance_port}"     ]] || echo instance_port=${instance_port}         ) \
    $([[ -z "${max_connection}"    ]] || echo max_connection=${max_connection}       ) \
    $([[ -z "${port}"              ]] || echo port=${port}                           ) \
    $([[ -z "${private_key}"       ]] || echo private_key=${private_key}             ) \
    $([[ -z "${protocol}"          ]] || echo protocol=${protocol}                   ) \
    $([[ -z "${public_key}"        ]] || echo public_key=${public_key}               ) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}
