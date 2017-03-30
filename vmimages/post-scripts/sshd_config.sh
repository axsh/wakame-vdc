#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

function config_sshd_config() {
  local sshd_config_path=$1 keyword=$2 value=$3
  [[ -a "${sshd_config_path}" ]] || { echo "[ERROR] file not found: ${sshd_config_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${keyword}" ]] || { echo "[ERROR] Invalid argument: keyword:${keyword} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${value}"   ]] || { echo "[ERROR] Invalid argument: value:${value} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  egrep -q -w "^${keyword}" ${sshd_config_path} && {
    # enabled
    sed -i "s,^${keyword}.*,${keyword} ${value},"  ${sshd_config_path}
  } || {
    # commented parameter is "^#keyword value".
    # therefore this case should *not* be included white spaces between # and keyword.
    egrep -q -w "^#${keyword}" ${sshd_config_path} && {
      # disabled
      sed -i "s,^#${keyword}.*,${keyword} ${value}," ${sshd_config_path}
    } || {
      # no match
      echo "${keyword} ${value}" >> ${sshd_config_path}
    }
  }

  egrep -q -w "^${keyword} ${value}" ${sshd_config_path}
}

{
  while read param value; do
    config_sshd_config /etc/ssh/sshd_config ${param} ${value}
  done < <(cat <<-EOS | egrep -v '^#|^$'
	#
	# "Top 20 OpenSSH Server Best Security Practices"
	# * http://www.cyberciti.biz/tips/linux-unix-bsd-openssh-server-best-practices.html
	#

	# 02: Only Use SSH Protocol 2
	Protocol 2

	# 03: Limit Users SSH Access
	DenyUsers root

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
	PasswordAuthentication no

	# 15: Disable Empty Passwords
	PermitEmptyPasswords no

	# Others
	StrictModes   yes
	X11Forwarding no
	UseDNS        no
	EOS
	)
}
