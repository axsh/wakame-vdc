#!/bin/bash

set -e -o pipefail

# Disable biosdevname allows "ethX" traditional interface name.
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="crashkernel=auto vconsole.font=latarcyrheb-sun16 vconsole.keymap=us crashkernel=auto net.ifnames=0 biosdevname=0"/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

