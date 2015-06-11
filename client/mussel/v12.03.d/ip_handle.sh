# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh
. ${BASH_SOURCE[0]%/*}/filter/${BASH_SOURCE[0]##*/}

task_expire_at() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X PUT $(urlencode_data \
    $(add_param time_to string) \
  ) \
  $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}
