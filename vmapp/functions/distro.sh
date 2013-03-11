# -*-Shell-script-*-
#
# description:
#  Linux Distribution
#
# requires:
#  bash, pwd
#  chroot
#
# imports:
#  utils: run_in_target
#

##
[[ -z "${__FUNCTIONS_DISTRO_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/utils.sh

##
function prevent_daemons_starting() {
  local chroot_dir=$1; shift
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  while [[ $# -ne 0 ]]; do
    run_in_target ${chroot_dir} chkconfig $1 off
    shift
  done
}

function unprevent_daemons_starting() {
  local chroot_dir=$1; shift
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  while [[ $# -ne 0 ]]; do
    run_in_target ${chroot_dir} chkconfig $1 on
    shift
  done
}

function prevent_interfaces_booting() {
  local chroot_dir=$1; shift
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  #
  # specific nic
  #   prevent_interfaces_booting ${chroot_dir} eth0 eth1 eth2
  # wildcard
  #   prevent_interfaces_booting ${chroot_dir} eth*
  #
  local ifcfg_path

  while [[ $# -ne 0 ]]; do
    # extract file path(s) even if wirldcard used
    for ifcfg_path in ${chroot_dir}/etc/sysconfig/network-scripts/ifcfg-${1}; do
      sed -i -e "s/^ONBOOT=yes/ONBOOT=no/" ${ifcfg_path}
      egrep -q "^ONBOOT=" ${ifcfg_path} || { echo ONBOOT=no >> ${ifcfg_path}; }
    done

    shift
  done
}

##
__FUNCTIONS_DISTRO_INCLUDED__=1
