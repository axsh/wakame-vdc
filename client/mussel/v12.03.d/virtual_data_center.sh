# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param vdc_spec strfile) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}
