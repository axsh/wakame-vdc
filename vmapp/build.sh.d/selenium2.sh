# -*-Shell-script-*-
#
# description:
#  load balancer
#
# requires:
#  bash, pwd
#  sed, cat, rm, egrep
#
# imports:
#  utils:     run_in_target
#  distro:    prevent_daemons_starting
#

##
[[ -z "${__BUILD_SELENIUM2_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh

##
function presetup_selenium2() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  # https://openshift.redhat.com/community/blogs/selenium-ruby-jenkins
  run_in_target ${chroot_dir} yum install -y \
   make rubygems ruby-devel xorg-x11-font* wget \
   xorg-x11-server-Xvfb \
   libffi-devel gcc
}

function configure_selenium2() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} gem install --no-ri --no-rdoc \
   selenium-webdriver \
   headless \
   json
}

function install_selenium2() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_selenium2  ${chroot_dir}
  configure_selenium2 ${chroot_dir}
}

##
__BUILD_SELENIUM2_INCLUDED__=1
