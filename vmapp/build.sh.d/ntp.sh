# -*-Shell-script-*-
#
# description:
#  ntp
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#

##
[[ -z "${__BUILD_NTP_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh

##
function install_ntp_rpm() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y ntp ntpdate
}

function unprevent_ntp_starting() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  unprevent_daemons_starting ${chroot_dir} ntpd ntpdate
}

function configure_ntp() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  unprevent_ntp_starting ${chroot_dir}
}

function install_ntp() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_ntp_rpm ${chroot_dir}
  configure_ntp   ${chroot_dir}
}

##
__BUILD_NTP_INCLUDED__=1
