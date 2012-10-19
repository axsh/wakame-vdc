#!/bin/bash

set -e

# The states to change
declare -A states
states["scheduling"]="terminated"
states["pending"]="terminated"
states["shuttingdown"]="terminated"
states["halting"]="halted"

# Check if a host node was specified and exit if not
host_node=$1
if [ -z "$host_node" ]; then
  echo "Error: No host node was set."
  echo "Usage: $0 HOST_NODE_UUID"
  exit 1
fi

# Determine Wakame root directory. This script needs to reside in $dcmgr_root/script
dcmgr_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Change directory so we cann call vdc-manage
cd $dcmgr_root/bin

# Returns the commands to feed to vdc-manage
function get_commands {
  ./vdc-manage instance show $host_node | while read line; do
    [ -z "$line" ] || {
      inst=( $line )
      uuid=${inst[0]}
      destination_state=${states[${inst[2]}]}
    }

    [ -n "$destination_state" ] && {
      echo "instance force-state $uuid $destination_state"
    }
  done
}

get_commands | ./vdc-manage -e > /dev/null
