# -*-Shell-script-*-
#
# description:
#  haproxy
#
# requires:
#  bash, pwd
#
# imorts:
#  utils: run_in_target
#  epel:  install_epel
#

##
[[ -z "${__BUILD_HAPROXY_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/epel.sh

##
function presetup_haproxy() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_epel  ${chroot_dir}
}
function install_haproxy() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_haproxy ${chroot_dir}
  run_in_target ${chroot_dir} yum install -y haproxy
}

##
__BUILD_HAPROXY_INCLUDED__=1
