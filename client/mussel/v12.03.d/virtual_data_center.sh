# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param type       string) \
    $(add_param spec       string) \
    $(add_param spec_file strfile) \
   ) \
   $(base_uri)/${namespace}s.$(suffix)
}
