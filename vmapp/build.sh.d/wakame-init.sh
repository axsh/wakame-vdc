# -*-Shell-script-*-
#
# description:
#  wakame-init
#
# requires:
#  bash, pwd
#  sed, cat, rsync, chmod, chown
#
# imports:
#  distro: prevent_interfaces_booting
#

##
[[ -z "${__BUILD_WAKAME_INIT_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh

##
declare wakame_init_rhel_path=$(cd ${BASH_SOURCE[0]%/*} && pwd)/../../wakame-init/rhel/6/wakame-init
declare wakame_init_ubuntu_path=$(cd ${BASH_SOURCE[0]%/*} && pwd)/../../wakame-init/ubuntu/10.04/wakame-init

##
function install_wakame_init() {
  local chroot_dir=$1 metadata_type=$2 distro=$3
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  case "${metadata_type}" in
  md)
    prevent_interfaces_booting ${chroot_dir} eth*
    ;;
  ms|mcd)
    ;;
  *)
    echo "[ERROR] unknown metadata_type:${metadata_type} ${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1;
    ;;
  esac
  local wakame_init_path
  case "${distro}" in
  centos|rhel)
    wakame_init_path=${wakame_init_rhel_path}
    ;;
  ubuntu|debian)
    wakame_init_path=${wakame_init_ubuntu_path}
    ;;
  *)
    echo "[ERROR] not supported distro:${distro} ${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1;
    ;;
  esac

  printf "[DEBUG] Installing wakame-init script\n"
  cat <<-EOS >> ${chroot_dir}/etc/rc.local
	/etc/wakame-init ${metadata_type}
	EOS
  cat ${chroot_dir}/etc/rc.local

  rsync -a ${wakame_init_rhel_path} ${chroot_dir}/etc/wakame-init
  chmod 755 ${chroot_dir}/etc/wakame-init
  chown 0:0 ${chroot_dir}/etc/wakame-init
}

##
__BUILD_WAKAME_INIT_INCLUDED__=1
