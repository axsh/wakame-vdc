# -*-Shell-script-*-
#
# description:
#  jre6
#
# requires:
#  bash, pwd
#  rsync
#
# imorts:
#  utils: run_in_target
#

##
[[ -z "${__BUILD_HAPROXY_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh

## http://java.com/en/download/manual_v6.jsp
declare jre6_ver=${jre6_ver:-1.6.0_38}
declare jre6_uri_32="http://javadl.sun.com/webapps/download/AutoDL?BundleId=71302"
declare jre6_uri_64="http://javadl.sun.com/webapps/download/AutoDL?BundleId=71304"

declare jre6_name=${jre6_name:-jre-6u-linux-rpm.bin}
declare jre6_path=${jre6_path:-/tmp/${jre6_name}}

##
function presetup_jre6() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  local jre6_location=
  case "$(arch)" in
  i*86)
    jre6_location=${jre6_uri_32}
    ;;
  x86_64)
    jre6_location=${jre6_uri_64}
    ;;
  esac

  run_in_target ${chroot_dir} curl -L \"${jre6_location}\" -o ${jre6_path}
}

function prepare_jre6() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y which
}

function cleanup_jre6() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} rm -f ${jre6_path}
}

function install_jre6() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_jre6 ${chroot_dir}
  prepare_jre6  ${chroot_dir}
  run_in_target ${chroot_dir} "cd /tmp && sh ${jre6_path}"
  cleanup_jre6  ${chroot_dir}
}

##
__BUILD_HAPROXY_INCLUDED__=1
