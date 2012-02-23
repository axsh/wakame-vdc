#!/bin/bash

for i in `sudo ../ovs/bin/ovs-vsctl list-ports br0`; do
    if [ "$i" != "eth0" ]; then
        sudo ../ovs/bin/ovs-vsctl del-port br0 $i
    fi;
done