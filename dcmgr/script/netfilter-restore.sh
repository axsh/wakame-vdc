#!/bin/bash
iptables_save_file=${iptables_save_file:-/etc/iptables-save}
ebtables_save_file=${ebtables_save_file:-/etc/ebtables-save}

cat ${iptables_save_file} | iptables-restore
ebtables --atomic-file ${ebtables_save_file} --atomic-commit
