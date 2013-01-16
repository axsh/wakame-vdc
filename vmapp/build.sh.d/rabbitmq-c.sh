# -*-Shell-script-*-
#
# description:
#  rabbitmq-c
#
# requires:
#  bash, pwd
#
# imorts:
#  utils: run_in_target
#

##
[[ -z "${__BUILD_RABBITMQ_C_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh

##
declare AMQPTOOLS_RABBITHOME=${AMQPTOOLS_RABBITHOME:-/usr/local/src/rabbitmq/rabbitmq-c}
declare rabbitmq_c_name="rabbitmq-c"
declare rabbitmq_c_location="git://github.com/alanxz/rabbitmq-c.git"
declare rabbitmq_c_git_hash="d008bb0f322d188399441519aabf746d50ebd3b5"

##
function presetup_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y make gcc git autoconf automake libtool
}

function prepare_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "[[ -d "$(dirname ${AMQPTOOLS_RABBITHOME})" ]] || mkdir -p "$(dirname ${AMQPTOOLS_RABBITHOME})""
  run_in_target ${chroot_dir} "cd "$(dirname ${AMQPTOOLS_RABBITHOME})" && git clone ${rabbitmq_c_location} && cd ${rabbitmq_c_name} && git reset --hard ${rabbitmq_c_git_hash}"
  run_in_target ${chroot_dir} "cd ${AMQPTOOLS_RABBITHOME} && git submodule init && git submodule update"
}

function build_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd ${AMQPTOOLS_RABBITHOME} && autoreconf -i && ./configure --enable-static && make"
}

function deploy_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd ${AMQPTOOLS_RABBITHOME} && make install"
}

function cleanup_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  :
}

function install_rabbitmq_c() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_rabbitmq_c ${chroot_dir}
  prepare_rabbitmq_c  ${chroot_dir}
  build_rabbitmq_c    ${chroot_dir}
  deploy_rabbitmq_c   ${chroot_dir}
  cleanup_rabbitmq_c  ${chroot_dir}
}

##
__BUILD_RABBITMQ_C_INCLUDED__=1
