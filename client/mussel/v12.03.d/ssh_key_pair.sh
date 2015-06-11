# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/piped/${BASH_SOURCE[0]##*/}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param description     string) \
    $(add_param display_name    string) \
    $(add_param download_once   string) \
    $(add_param public_key     strfile) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3

  call_api -X PUT $(urlencode_data \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
