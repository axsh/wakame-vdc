#!/bin/sh
#
# $ vnic-ls.sh
# $ vnic-ls.sh -l
#

LANG=C
LC_ALL=C

list_vnic() {
  ip addr show | grep vif- | awk '{print $2}' | sed 's,:$,,'
}

show_vnic() {
  vnic=$1
  echo "[ ${vnic} ]"
  ip addr show  ${vnic} | sed 's,^,     ,'
  echo
}

case $1 in
-l*)
  list_vnic | while read vnic; do
    show_vnic ${vnic}
  done
  ;;
*)
  list_vnic 
  ;;
esac

exit 0
