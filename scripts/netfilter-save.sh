#!/bin/bash
iptables_save_file=${iptables_save_file:-/etc/iptables-save}
ebtables_save_file=${ebtables_save_file:-/etc/ebtables-save}

iptables-save > ${iptables_save_file}
ebtables --atomic-file ${ebtables_save_file} --atomic-save
