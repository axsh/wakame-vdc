#!/bin/bash

if [ "$1" = "tunnels" ]; then
    for i in `sudo ../ovs/bin/ovs-vsctl list-ports br0`; do
        if [[ "$i" =~ ^t-[a-zA-Z0-9]*-[0-9]*$ ]]; then
            sudo ../ovs/bin/ovs-vsctl del-port br0 $i
        fi;
    done

elif [ -z "$1" ]; then
    for i in `sudo ../ovs/bin/ovs-vsctl list-ports br0`; do
        if [ "$i" != "eth0" ]; then
            sudo ../ovs/bin/ovs-vsctl del-port br0 $i
        fi;
    done

else
    echo "Invalid argument."
fi
