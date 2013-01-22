# -*-Shell-script-*-
#
# description:
#  epel
#
# requires:
#  bash, pwd
#
# imorts:
#  utils: run_in_target
#

##
[[ -z "${__BUILD_EPEL_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh

##
function install_epel() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "rpm -qi epel-release || rpm -ivh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release"
  run_in_target ${chroot_dir} yum repolist
}

##
__BUILD_EPEL_INCLUDED__=1
