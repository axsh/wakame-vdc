# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param service_type    string) \
    $(add_param rule           strfile) \
    $(add_param description     string) \
    $(add_param display_name    string) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
    $(add_param service_type    string) \
    $(add_param rule           strfile) \
    $(add_param description     string) \
    $(add_param display_name    string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
