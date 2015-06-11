# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/filter/${BASH_SOURCE[0]##*/}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param name) \
    $(add_param description) \
  ) \
  $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
    $(add_param name) \
    $(add_param description) \
    $(add_param allow_new_networks) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}

task_add_offering_modes() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
    $(add_param mode) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/offering_modes/add.$(suffix)
}
