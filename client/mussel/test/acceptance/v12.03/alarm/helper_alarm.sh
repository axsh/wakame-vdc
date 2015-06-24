#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

host_ssh_user=${host_ssh_user:-root}
host_ipaddr=${host_ipaddr:-10.0.2.15}
host_private_key=${host_private_key:-id_rsa}
host_ssh_key_pair_path=${host_ssh_key_pair_path:-~/.ssh/${host_private_key}}
sleep_sec=3

## functions

