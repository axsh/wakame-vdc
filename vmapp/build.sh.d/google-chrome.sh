# -*-Shell-script-*-
#
# description:
#  chrome
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#

##
[[ -z "${__BUILD_GOOGLE_CHROME_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh

##
function render_chrome_repo() {
  cat <<-'EOS'
	[google-chrome]
	name=google-chrome - $basearch
	baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
	enabled=1
	gpgcheck=1
	gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
	EOS
}

function install_chrome_repo() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  render_chrome_repo > ${chroot_dir}/etc/yum.repos.d/google-chorme.repo
}

function install_chrome_rpm() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y google-chrome-stable
}

function presetup_chrome() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_chrome_repo ${chroot_dir}
}

function configure_chrome() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} /etc/init.d/atd stop
}

function install_chrome() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_chrome    ${chroot_dir}
  install_chrome_rpm ${chroot_dir}
  configure_chrome   ${chroot_dir}
}

##
__BUILD_GOOGLE_CHROME_INCLUDED__=1
