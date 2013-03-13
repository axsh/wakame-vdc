# -*-Shell-script-*-
#
# 11.12
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param ha_enabled         string) \
    $(add_param host_node_id       string) \
    $(add_param hostname           string) \
    $(add_param image_id           string) \
    $(add_param instance_spec_id   string) \
    $(add_param network_scheduler  string) \
    $(add_param security_groups     array) \
    $(add_param ssh_key_id         string) \
    $(add_param user_data         strfile) \
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
