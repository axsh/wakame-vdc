#!/usr/bin/env bash
#
# If remotely connected, use a script to ensure the
# network gets restarted.

work_dir=${work_dir:?"work_dir needs to be set"}

last_if_name=""

while true; do
    if_name=`brctl show | grep '^br0' | sed -e 's:[\t][\t]*:\t:g' | cut -f 4`
    
    if [ -z "$if_name" ] || [ "$last_if_name" == "$if_name" ]; then break; fi

    echo brctl delif br0 \"$if_name\"
    brctl delif br0 "$if_name"
    last_if_name="$if_name"
done

set +e

ip link set br0 down || true
brctl delbr br0 || true

/etc/init.d/ovs-switch restart
/etc/init.d/networking restart

echo "Sleeping for 3 seconds..."
sleep 3

$work_dir/ovs/bin/ovs-vsctl list-ports br0

# Clear the flows and add default one in order to ensure we can
# connect even if there's some bad flows cached.
$work_dir/ovs/bin/ovs-ofctl del-flows br0 && $work_dir/ovs/bin/ovs-ofctl add-flow br0 priority=0,action=normal

echo "Setting OpenFlow controller for 'br0', may cause connection loss for 15 seconds."
$work_dir/ovs/bin/ovs-vsctl set-controller br0 tcp:127.0.0.1
$work_dir/ovs/bin/ovs-vsctl get-controller br0

$work_dir/ovs/bin/ovs-ofctl dump-flows br0

echo
echo "Disabling use of in-band communication with controller. This results in packets from localhost being properly processed by the flow table."
echo
echo "Note that use of unix socket for controller communication is preferrable for stability."
$work_dir/ovs/bin/ovs-vsctl set bridge br0 other_config:disable-in-band=true
