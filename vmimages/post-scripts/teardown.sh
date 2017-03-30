#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

if [[ -f /etc/yum.repos.d/CentOS-Base.repo.saved ]]; then
  mv /etc/yum.repos.d/CentOS-Base.repo.saved /etc/yum.repos.d/CentOS-Base.repo
fi

rm -f /etc/ssh/ssh_host_*

while read varlog; do
  cp /dev/null ${varlog}
done < <(find /var/log/ -type f)

history -c
