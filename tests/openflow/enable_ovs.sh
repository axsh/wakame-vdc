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

echo
export BRCOMPAT=yes

/etc/init.d/ovs-switch restart
/etc/init.d/networking restart

PATH=/usr/share/axsh/ovs-switch/bin/:$PATH

# Sleep to allow time for Open vSwitch to get initiated.
sleep 1

echo
echo "lsmod | grep bridge"
lsmod | grep bridge
echo "ovs-vsctl list-ports br0"
ovs-vsctl list-ports br0

echo
echo "Setting OpenFlow controller address for 'br0'."
ovs-vsctl set-controller br0 tcp:127.0.0.1
ovs-vsctl get-controller br0

echo "ovs-ofctl dump-flows br0"
ovs-ofctl dump-flows br0
