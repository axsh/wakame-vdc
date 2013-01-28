# -*-Shell-script-*-
#
# description:
#  jenkins-git
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#

##
[[ -z "${__BUILD_JENKINS_GIT_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/jenkins.sh

##
function presetup_jenkins_git() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_jenkins ${chroot_dir}
  run_in_target ${chroot_dir} yum install -y git
  run_in_target ${chroot_dir} "[[ -d /var/lib/jenkins/plugins ]] || mkdir -p /var/lib/jenkins/plugins"
}

function deploy_jenkins_git() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} curl -L http://updates.jenkins-ci.org/latest/git.hpi -o /var/lib/jenkins/plugins/git.hpi
}

function install_jenkins_git() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_jenkins_git ${chroot_dir}
  deploy_jenkins_git   ${chroot_dir}
}

##
__BUILD_JENKINS_GIT_INCLUDED__=1
