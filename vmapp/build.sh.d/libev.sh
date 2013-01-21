# -*-Shell-script-*-
#
# description:
#  libev
#
# requires:
#  bash, pwd
#
# imorts:
#  utils: run_in_target
#  epel:  install_epel
#

##
[[ -z "${__BUILD_LIBEV_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/epel.sh

##

function presetup_libev() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_epel ${chroot_dir}
}

function install_libev() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_libev ${chroot_dir}
  run_in_target ${chroot_dir} yum install -y libev libev-devel
}

##
__BUILD_LIBEV_INCLUDED__=1
