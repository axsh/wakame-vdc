#!/bin/bash

cmds=" /sbin/iptables-save /sbin/ebtables-save "
for cmd in ${cmds}; do
  echo "===>>> [#$$] ${cmd} ==="
  eval ${cmd} | egrep -v '^#' | sed "s,^,#$$ ${cmd}: ,"
done

