#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1

packages="curl man ntp ntpdate sudo rsync git make screen nmap lsof strace tcpdump traceroute telnet ltrace dnsutils sysstat netcat-openbsd acl"
chroot ${chroot_dir} apt-get update
chroot ${chroot_dir} apt-get install -y ${packages}
