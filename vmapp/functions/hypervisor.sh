# -*-Shell-script-*-
#
# description:
#  load balancer
#
# requires:
#  bash, pwd
#
# imports:
#  distro:    flush_etc_sysctl
#

##
[[ -z "${__BUILD_HYPERVISOR_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh

##

function configure_hypervisor() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  case ${VDC_HYPERVISOR} in
  lxc)
    #
    # lxc system container will overwrite lxc host parameter even if running sysctl in a lxc container.
    # unless running flush a lxc container /etc/sysctl.ctl, the lxc host parameters will be set to rhel6 default value.
    #
    # this means following:
    # * disabling netfilter on bridges on lxc host.
    #
    flush_etc_sysctl ${chroot_dir}
    ;;
  *)
    ;;
  esac
}

##
__BUILD_HYPERVISOR_INCLUDED__=1
