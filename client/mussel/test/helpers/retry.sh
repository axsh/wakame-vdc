# -*-Shell-script-*-
#
# requires:
#   bash
#

## retry

function retry_until() {
  local blk="$@"

  local wait_sec=${RETRY_WAIT_SEC:-120}
  local sleep_sec=${RETRY_SLEEP_SEC:-3}
  local tries=0
  local start_at=$(date +%s)
  local chk_cmd=

  while :; do
    eval "${blk}" && {
      break
    } || {
      sleep ${sleep_sec}
    }

    tries=$((${tries} + 1))
    if [[ "$(($(date +%s) - ${start_at}))" -gt "${wait_sec}" ]]; then
      echo "Retry Failure: Exceed ${wait_sec} sec: Retried ${tries} times" >&2
      return 1
    fi
    echo [$(date +%FT%X) "#$$"] time:${tries} "eval:${chk_cmd}" >&2
  done
}

function retry_while() {
  local blk="$@"
  retry_until ! ${blk}
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
