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
#  distro:    prevent_daemons_starting, prevent_interfaces_booting
#  haproxy:   install_haproxy
#  stud:      install_stud
#  amqptools: install_amqptools
#

##
[[ -z "${__BUILD_LB_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/haproxy.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/stud.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/amqptools.sh

##
function configure_lb_networking() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  sed -i -e "s/^NETWORKING=\"yes\"/NETWORKING=\"no\"/" ${chroot_dir}/etc/sysconfig/network

  # Clear network configurations from template
  prevent_interfaces_booting ${chroot_dir} eth*

  cat <<-'EOS' >> ${chroot_dir}/etc/rc.local
	. /metadata/user-data
	route add -net ${AMQP_SERVER} netmask 255.255.255.255 dev eth1
	EOS
}

function configure_lb_daemons_starting() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  rm -f ${chroot_dir}/etc/haproxy/haproxy.cfg
  prevent_daemons_starting ${chroot_dir} haproxy postfix rsyslog sshd
}

function configure_lb_kmod() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  cat <<-'EOS' > ${chroot_dir}/etc/modprobe.d/blacklist
	blacklist ipv6
	blacklist net-pf-10
	EOS
}

function configure_lb_amqptools() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  local AMQPTOOLS_INSTALLROOT=/opt/axsh/wakame-vdc/amqptools/bin
  run_in_target ${chroot_dir} "[[ -d ${AMQPTOOLS_INSTALLROOT} ]] || mkdir -p ${AMQPTOOLS_INSTALLROOT}"

  local amqptool amqptools="amqpspawn amqpsend"
  for amqptool in ${amqptools}; do
    run_in_target ${chroot_dir} "ln /usr/local/bin/${amqptool} ${AMQPTOOLS_INSTALLROOT}/${amqptool}"
  done
}

function configure_lb() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  configure_lb_amqptools        ${chroot_dir}
  configure_lb_networking       ${chroot_dir}
  configure_lb_daemons_starting ${chroot_dir}
  configure_lb_kmod             ${chroot_dir}
}

function presetup_lb() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_haproxy     ${chroot_dir}
  install_stud        ${chroot_dir}
  install_amqptools   ${chroot_dir}
}

function install_lb() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_lb  ${chroot_dir}
  configure_lb ${chroot_dir}
}

##
__BUILD_LB_INCLUDED__=1
