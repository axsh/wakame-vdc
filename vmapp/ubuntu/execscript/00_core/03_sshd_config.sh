#!/bin/bash
#
# requires:
#  bash
#
set -e

declare chroot_dir=$1
declare passwd_login=$2

. ./functions.sh

while read param value; do
    config_sshd_config ${chroot_dir}/etc/ssh/sshd_config ${param} ${value}
    done < <(cat <<-EOS | egrep -v '^#|^$'
#
# "Top 20 OpenSSH Server Best Security Practices"
# * http://www.cyberciti.biz/tips/linux-unix-bsd-openssh-server-best-practices.html
#

# 02: Only Use SSH Protocol 2
Protocol 2

# 03: Limit Users SSH Access
#DenyUsers root

# 04: Configure Idle Log Out Timeout Interval
ClientAliveInterval 0
ClientAliveCountMax 3

# 05: Disable .rhosts Files
IgnoreRhosts yes

# 06: Disable Host-Based Authentication
HostbasedAuthentication no

# 07: Disable root Login via SSH
PermitRootLogin no

# 09: Change SSH Port and Limit IP Binding
Port 22

# 11: Use Public Key Based Authentication
PasswordAuthentication yes

# 15: Disable Empty Passwords
PermitEmptyPasswords no

# Others
StrictModes   no
X11Forwarding no
EOS
)

if [[ ${passwd_login} = "disabled" ]]; then
    config_sshd_config ${chroot_dir}/etc/ssh/sshd_config PasswordAuthentication no
fi

