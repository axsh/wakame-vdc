# -*-Shell-script-*-
#
# description:
#  chromedriver
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#

##
[[ -z "${__BUILD_CHROMEDRIVER_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/google-chrome.sh

##
declare chromedriver_ver=23.0.1240.0
declare chromedriver_arch=$(
  case "$(arch)" in
  i*86)   echo 32 ;;
  x86_64) echo 64 ;;
  esac
)
declare chromedriver_file=chromedriver_linux${chromedriver_arch}_${chromedriver_ver}.zip

##
function presetup_chromedriver() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y unzip curl
}

function prepare_chromedriver() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} curl http://chromedriver.googlecode.com/files/${chromedriver_file} -o /tmp/${chromedriver_file}
  run_in_target ${chroot_dir} "cd /tmp && unzip /tmp/${chromedriver_file}"
}

function deploy_chromedriver() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} mv /tmp/chromedriver /usr/local/bin
}

function install_chromedriver() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_chromedriver    ${chroot_dir}
  prepare_chromedriver     ${chroot_dir}
  deploy_chromedriver      ${chroot_dir}
}

##
__BUILD_CHROMEDRIVER_INCLUDED__=1
