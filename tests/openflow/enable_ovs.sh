#!/usr/bin/env bash
#
# If remotely connected, use a script to ensure the
# network gets restarted.

last_if_name=""

while true; do
    if_name=`brctl show | grep '^br0' | sed -e 's:[\t][\t]*:\t:g' | cut -f 4`
    
    if [ -z "$if_name" ] || [ "$last_if_name" == "$if_name" ]; then break; fi

    echo brctl delif br0 \"$if_name\"
    brctl delif br0 "$if_name"
    last_if_name="$if_name"
done

echo ip link set br0 down
ip link set br0 down
echo brctl delbr br0
brctl delbr br0

export BRCOMPAT=yes

/etc/init.d/ovs-switch restart
/etc/init.d/networking restart
