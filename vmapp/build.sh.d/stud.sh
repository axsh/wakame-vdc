# -*-Shell-script-*-
#
# description:
#  stud
#
# requires:
#  bash, pwd
#  wget, tar, sed
#
# imorts:
#  utils: run_in_target
#  libev: install_libev
#

##
[[ -z "${__BUILD_STUD_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/libev.sh

##
declare stud_name="stud-master"
declare stud_tarball="stud.tar.gz"
declare stud_location="https://github.com/axsh/stud/archive/master.tar.gz"

##
function presetup_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y openssl openssl-devel make gcc tar
  install_libev ${chroot_dir}
}

function prepare_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "curl -L ${stud_location} -o /tmp/${stud_tarball}"
  run_in_target ${chroot_dir} "tar zxf /tmp/${stud_tarball} -C /tmp"
  run_in_target ${chroot_dir} "sed -i s,I/usr/local/include,I/usr/include/libev, /tmp/${stud_name}/Makefile"
  run_in_target ${chroot_dir} "sed -i s,L/usr/local/lib,L/usr/lib64,             /tmp/${stud_name}/Makefile"
}

function build_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${stud_name} && make"
}

function deploy_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${stud_name} && make PREFIX=/usr install"
}

function cleanup_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "rm -rf /tmp/${stud_name}"
}

function install_stud() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_stud ${chroot_dir}
  prepare_stud  ${chroot_dir}
  build_stud    ${chroot_dir}
  deploy_stud   ${chroot_dir}
  cleanup_stud  ${chroot_dir}
}

##
__BUILD_STUD_INCLUDED__=1
