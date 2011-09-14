#!/usr/bin/env bash
#
# If remotely connected, use a script to ensure the
# network gets restarted.
brctl delif br0 eth0
ip link set br0 down
brctl delbr br0

service ovs-switch start
/etc/init.d/networking restart
