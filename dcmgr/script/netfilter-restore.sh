#!/bin/bash
iptables_save_file=${iptables_save_file:-/etc/iptables-save}
ebtables_save_file=${ebtables_save_file:-/etc/ebtables-save}

if [ -f $iptables_save_file ]; then
  cat ${iptables_save_file} | iptables-restore
else
  echo "Warning: ${iptables_save_file} not found. Not restoring iptables rules."
fi

if [ -f $ebtables_save_file ]; then
  ebtables --atomic-file ${ebtables_save_file} --atomic-commit
else
  echo "Warning: ${ebtables_save_file} not found. Not restoring ebtables rules."
fi
