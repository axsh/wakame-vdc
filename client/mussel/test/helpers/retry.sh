# -*-Shell-script-*-
#
# requires:
#   bash
#

## retry

function retry_until() {
  local blk="$@"

  local wait_sec=120
  local tries=0
  local start_at=$(date +%s)

  while :; do
    eval "${blk}" && {
      break
    } || {
      sleep 3
    }

    tries=$((${tries} + 1))
    if [[ "$(($(date +%s) - ${start_at}))" -gt "${wait_sec}" ]]; then
      echo "Retry Failure: Exceed ${wait_sec} sec: Retried ${tries} times" >&2
      return 1
    fi
    echo [$(date +%FT%X) "#$$"] time:${tries} "eval:${blk}"
  done
}

function retry_while() {
  local blk="$@"
  ! retry_until ${blk}
}

## check

function open_port?() {
  local ipaddr=$1 protocol=$2 port=$3

  local nc_opts="-w 3"
  case ${protocol} in
  tcp) ;;
  udp) nc_opts="${nc_opts} -u";;
    *) ;;
  esac

  echo | nc ${nc_opts} ${ipaddr} ${port} >/dev/null
}

function network_connection?() {
  local ipaddr=$1
  ping -c 1 -W 3 ${ipaddr}
}

## wait for *to be*

function wait_for_network_to_be_ready() {
  local ipaddr=$1
  retry_until "network_connection? ${ipaddr}"
}

function wait_for_port_to_be_ready() {
  local ipaddr=$1 protocol=$2 port=$3
  retry_until "open_port? ${ipaddr} ${protocol} ${port}"
}

function wait_for_sshd_to_be_ready() {
  local ipaddr=$1
  wait_for_port_to_be_ready ${ipaddr} tcp 22
}

function wait_for_httpd_to_be_ready() {
  local ipaddr=$1
  wait_for_port_to_be_ready ${ipaddr} tcp 80
}

## wait for *not to be*

function wait_for_network_not_to_be_ready() {
  local ipaddr=$1
  retry_until "! network_connection? ${ipaddr}"
}

function wait_for_port_not_to_be_ready() {
  local ipaddr=$1 protocol=$2 port=$3
  retry_until "! open_port? ${ipaddr} ${protocol} ${port}"
}

function wait_for_sshd_not_to_be_ready() {
  local ipaddr=$1
  wait_for_port_not_to_be_ready ${ipaddr} tcp 22
}

function wait_for_httpd_not_to_be_ready() {
  local ipaddr=$1
  wait_for_port_not_to_be_ready ${ipaddr} tcp 80
}

##

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
  [[ "$(run_cmd ${namespace} show ${uuid} | hash_value ${key})" == "${val}" ]]
}
