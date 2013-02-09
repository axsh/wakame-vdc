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
    $(add_param balance_algorithm string) \
    $(add_param cookie_name       string) \
    $(add_param display_name      string) \
    $(add_param engine            string) \
    $(add_param instance_port     string) \
    $(add_param max_connection    string) \
    $(add_param port              string) \
    $(add_param private_key       string) \
    $(add_param protocol          string) \
    $(add_param public_key        string) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_poweroff() {
  cmd_put $*
}

task_poweron() {
  cmd_put $*
}
