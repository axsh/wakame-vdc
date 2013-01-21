# -*-Shell-script-*-
#
# description:
#  amqptools
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:      run_in_target
#  rabbitmq-c: install_rabbitmq_c
#

##
[[ -z "${__BUILD_AMQPTOOLG_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/rabbitmq-c.sh

##
declare amqptools_name="amqptools"
# git://github.com/rmt/amqptools.git
declare amqptools_location="git://github.com/saicologic/amqptools.git"
declare amqptools_git_hash="fa9e71b425a69b6612373b957f7955a77ca6ce58"

##
function presetup_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y make gcc git autoconf automake libtool
  install_rabbitmq_c ${chroot_dir}
}

function prepare_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp && git clone ${amqptools_location} && cd ${amqptools_name} && git reset --hard ${amqptools_git_hash}"
}

function build_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${amqptools_name} && make"
}

function deploy_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${amqptools_name} && make AMQPTOOLS_INSTALLROOT=${AMQPTOOLS_INSTALLROOT:-/usr/local/bin} install"
}

function cleanup_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "rm -rf /tmp/${amqptools_name}"
}

function install_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_amqptools ${chroot_dir}
  prepare_amqptools  ${chroot_dir}
  build_amqptools    ${chroot_dir}
  deploy_amqptools   ${chroot_dir}
  cleanup_amqptools  ${chroot_dir}
}

##
__BUILD_AMQPTOOLG_INCLUDED__=1
