# -*-Shell-script-*-
#
# requires:
#   bash
#

function hash_value() {
  local key=$1 line

  #
  # NF=2) ":id: i-xxx"
  # NF=3) "- :vif_id: vif-qqjr0ial"
  #
  egrep -w ":${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
}

function document_pair?() {
  local namespace=$1 uuid=$2 key=$3 val=$4
  # make sure to get value of first level key.
  #
  # [OK] ':state: running'
  # [NG] '  :state: attached'
  #
  [[ "$(run_cmd ${namespace} show ${uuid} | egrep -w "^:${key}:" | awk '{print $2}')" == "${val}" ]]
}
