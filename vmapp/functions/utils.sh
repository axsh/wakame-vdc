# -*-Shell-script-*-
#
# description:
#  Various utility functions
#
# requires:
#  bash, pwd
#  chroot
#
# imports:
#

##
[[ -z "${__FUNCTIONS_UTILS_INCLUDED__}" ]] || return 0

##
function checkroot() {
  #
  # Check if we're running as root, and bail out if we're not.
  #
  [[ "${UID}" -ne 0 ]] && {
    echo "[ERROR] Must run as root." >&2
    return 1
  } || :
}

function run_in_target() {
  local chroot_dir=$1; shift; local args="$*"
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  chroot ${chroot_dir} bash -e -c "${args}"
}

function load_config() {
  local config_path=$1
  [[ -a "${config_path}" ]] || { echo "[ERROR] file not found: ${config_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  . ${config_path}
}

##
__FUNCTIONS_UTILS_INCLUDED__=1
