#!/bin/bash

set -e -o pipefail

USERNAME=${USERNAME:-centos}

# account:vagrant
groupadd $USERNAME
useradd -g $USERNAME -s /bin/bash -m $USERNAME
echo umask 022 >> /home/$USERNAME/.bashrc
echo $USERNAME:$USERNAME | chpasswd
usermod -L root

echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^\(^Defaults\s*requiretty\).*/# \1/" /etc/sudoers

