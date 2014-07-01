# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param resource_id                string) \
    $(add_param metric_name                string) \
    $(add_param evaluation_periods         string) \
    $(add_param notification_periods       string) \
    $(add_param display_name               string) \
    $(add_param description                string) \
    $(add_param params                       hash) \
    $(add_param ok_actions                   hash) \
    $(add_param alarm_actions                hash) \
    $(add_param insufficient_data_actions    hash) \
  ) \
  $(base_uri)/${namespace}s.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param enabled                    string) \
    $(add_param evaluation_periods         string) \
    $(add_param notification_periods       string) \
    $(add_param display_name               string) \
    $(add_param description                string) \
    $(add_param params                       hash) \
    $(add_param ok_actions                   hash) \
    $(add_param alarm_actions                hash) \
    $(add_param insufficient_data_actions    hash) \
  ) \
  $(base_uri)/${namespace}s/${uuid}.$(suffix)
}
