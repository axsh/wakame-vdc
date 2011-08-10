#!/bin/bash
# jason _\@_ broken.net
# 20May2011 - Kid tested, mother approved
#
# via http://broken.net/uncategorized/simple-comstar-iscsi-fcoe-fc-config-view/

echo --- List View and Associated Host Groups IQNs ---
for i in `stmfadm list-lu | cut -d" " -f3`; do
   stmfadm list-view -l $i
   host_group=`stmfadm list-view -l $i | grep "Host group" | cut -d: -f 2`
   client_iqn=`stmfadm list-hg -v $host_group| grep -v "Host Group"`
   echo Client IQN $client_iqn

   echo
done

echo --- Target group config ----

stmfadm list-tg -v
echo

echo --- LU List \(verbose\) ---
stmfadm list-lu -v
