#!/bin/sh
#
# $ netfilter-stat.sh
# $ netfilter-stat.sh -l
#
LANG=C
LC_ALL=C

abs_path=$(cd $(dirname $0) && pwd)

dump_netfilter() {
  {
  sudo iptables-save
  sudo ebtables -t filter -L
  sudo ebtables -t nat    -L
 } | egrep '^-' | egrep -v -w -i log
}

case $1 in
-l*)
  for vnic in $(${abs_path}/vnic-ls.sh); do
    echo "[ ${vnic} ]"
    dump_netfilter | egrep ${vnic} | sed 's,^,     ,'
  done
  ;;
*)
  dump_netfilter
  ;;
esac

exit 0
