#!/bin/bash

loop_from=8
loop_to=127

[ -f /etc/udev/makedev.d/50-udev.nodes ] || touch /etc/udev/makedev.d/50-udev.nodes

for i in $(seq ${loop_from} ${loop_to}); do
  egrep -q "^loop${i}\$" /etc/udev/makedev.d/50-udev.nodes || echo "loop$i" >> /etc/udev/makedev.d/50-udev.nodes
done
