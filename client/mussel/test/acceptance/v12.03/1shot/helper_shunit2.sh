# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

## include files

. ${BASH_SOURCE[0]%/*}/../helper_shunit2.sh

## group variables

## group functions

function ssh() {
  $(which ssh) -o 'StrictHostKeyChecking no' $@
}

function check_port() {
  local ipaddr=$1 protocol=$2 port=$3

  local nc_opts="-w 1"
  case ${protocol} in
  tcp) ;;
  udp) nc_opts="${nc_opts} -u";;
    *) ;;
  esac

  echo | nc ${nc_opts} ${ipaddr} ${port} >/dev/null
}

function check_network_connection() {
  local ipaddr=$1

  ping -c 1 -W 1 ${ipaddr}
}
