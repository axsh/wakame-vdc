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

##
__FUNCTIONS_DISTRO_INCLUDED__=1
