# -*-Shell-script-*-
#
# description:
#  jenkins
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#

##
[[ -z "${__BUILD_JENKINS_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/ntp.sh

##
function presetup_jenkins() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_ntp   ${chroot_dir}
  run_in_target ${chroot_dir} yum install -y java-1.6.0-openjdk
}

function prepare_jenkins() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} curl http://pkg.jenkins-ci.org/redhat/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
  run_in_target ${chroot_dir} rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
}

function install_jenkins_rpm() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} yum install -y jenkins
}

function configure_jenkins() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  unprevent_daemons_starting ${chroot_dir} jenkins
  run_in_target ${chroot_dir} sed -i "s,^JENKINS_USER=.*,JENKINS_USER=root," /etc/sysconfig/jenkins
}

function install_jenkins() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_jenkins    ${chroot_dir}
  prepare_jenkins     ${chroot_dir}
  install_jenkins_rpm ${chroot_dir}
  configure_jenkins   ${chroot_dir}
}

##
__BUILD_JENKINS_INCLUDED__=1
