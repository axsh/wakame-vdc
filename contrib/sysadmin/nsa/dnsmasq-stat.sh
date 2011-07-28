#!/bin/sh
#
# $ dnsmasq-stat.sh
# $ dnsmasq-stat.sh -l
#

LANG=C
LC_ALL=C


dnsmasq_ps() {
  ps -e -o command | egrep '[b]in/dnsmasq' | egrep -v "sed|$0" | while read line; do
    set ${line}

    confs=
    while [ $# -gt 0 ]; do
      case $1 in
      -*)
        printf "     %s\n" $1
        case $1 in
        --addn-hosts=*)
          confs="${confs} ${1##*=}"
          ;;
        --dhcp-hostsfile=*)
          confs="${confs} ${1##*=}"
          ;;
        --conf-file=*)
          confs="${confs} ${1##*=}"
          ;;
        esac
        ;;
      *)
        printf "  %s\n" $1
        ;;
      esac
      shift
    done
    echo
    for conf in ${confs}; do
      echo "  -> ${conf}"
      [ -f ${conf} ] && sed 's,^,     ,' ${conf}
      echo
    done
  done
}

case $1 in
-l*)
  dnsmasq_ps
  ;;
*)
  {
    ps -ef | egrep '[b]in/dnsmasq'
  }  | while read line; do
    echo ${line}
    echo
    set ${line}
    pstree -pal $2
  done
  ;;
esac

echo
sudo netstat -nap | grep dnsmasq

exit 0
