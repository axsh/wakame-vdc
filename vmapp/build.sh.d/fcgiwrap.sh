# -*-Shell-script-*-
#
# description:
#  fcgiwrap
#
# requires:
#  bash, pwd
#
# imorts:
#  utils:  run_in_target
#  distro: unprevent_daemons_starting
#  epel:   install_epel
#  nginx:  install_nginx
#

##
[[ -z "${__BUILD_FCGIWRAP_INCLUDED__}" ]] || return 0

##
declare fcgiwrap_name="fcgiwrap-master"
declare fcgiwrap_tarball="master.tar.gz"
declare fcgiwrap_location="https://github.com/gnosek/fcgiwrap/archive/master.tar.gz"

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/../functions/distro.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/epel.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/nginx.sh

##
function presetup_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  install_epel  ${chroot_dir}
  install_nginx ${chroot_dir}
  run_in_target ${chroot_dir} yum install -y make gcc tar spawn-fcgi fcgi-devel autoconf automake pkgconfig
}

function prepare_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "curl -fsSkL ${fcgiwrap_location} -o /tmp/${fcgiwrap_tarball}"
  run_in_target ${chroot_dir} "tar zxf /tmp/${fcgiwrap_tarball} -C /tmp"
  run_in_target ${chroot_dir} "cd /tmp/${fcgiwrap_name} && autoreconf -i && ./configure"
}

function build_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${fcgiwrap_name} && make"
}

function deploy_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "cd /tmp/${fcgiwrap_name} && make install"
}

function cleanup_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  run_in_target ${chroot_dir} "rm -rf /tmp/${fcgiwrap_name}"
}

function install_fcgiwrap() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  presetup_fcgiwrap ${chroot_dir}
  prepare_fcgiwrap  ${chroot_dir}
  build_fcgiwrap    ${chroot_dir}
  deploy_fcgiwrap   ${chroot_dir}
  cleanup_fcgiwrap  ${chroot_dir}
}

## demo

function render_fcgiwrap_envcgi() {
  cat <<-EOS
	#!/bin/bash
	#
	# requires:
	#  bash
	#  env, sort
	#
	cat <<_HEADER_
	Content-type: text/plain
	
	_HEADER_
	
	/bin/env | sort
	EOS
}

function install_fcgiwrap_envcgi() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  mkdir -p ${chroot_dir}/usr/share/nginx/html/cgi-bin
  render_fcgiwrap_envcgi > ${chroot_dir}/usr/share/nginx/html/cgi-bin/env.cgi
  chmod 755 ${chroot_dir}/usr/share/nginx/html/cgi-bin/env.cgi
}

function render_fcgiwrap_sleepcgi() {
  cat <<-EOS
	#!/bin/bash
	#
	# requires:
	#  bash
	#  env, sort
	#
	cat <<_HEADER_
	Content-type: text/plain
	
	_HEADER_
	
	/bin/sleep 600
	EOS
}

function install_fcgiwrap_sleepcgi() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  mkdir -p ${chroot_dir}/usr/share/nginx/html/cgi-bin
  render_fcgiwrap_sleepcgi > ${chroot_dir}/usr/share/nginx/html/cgi-bin/sleep.cgi
  chmod 755 ${chroot_dir}/usr/share/nginx/html/cgi-bin/sleep.cgi
}

function render_fcgiwrap_nginx() {
  cat <<-'EOS'
	server {
	  listen       80 default_server;
	  server_name  _;
	  location / {
	    root   /usr/share/nginx/html;
	    index  index.html index.htm;
	  }
	  error_page  404              /404.html;
	  location = /404.html {
	    root   /usr/share/nginx/html;
	  }
	  error_page   500 502 503 504  /50x.html;
	  location = /50x.html {
	    root   /usr/share/nginx/html;
	  }
	  location ~ ^/cgi-bin/.*\.cgi$
	  {
	    fastcgi_pass    127.0.0.1:8999;
	    fastcgi_read_timeout    5m;
	    fastcgi_index    index.cgi;
	    include /etc/nginx/fastcgi_params;
	  }
	}
	EOS
}

function configure_fcgiwrap_nginx() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  render_fcgiwrap_nginx > ${chroot_dir}/etc/nginx/conf.d/default.conf
}

function render_fcgiwrap_spawn_fcgi() {
  cat <<-EOS
	OPTIONS="-u nginx -g nginx -p 8999 -P /var/run/spawn-fcgi.pid -- /usr/local/sbin/fcgiwrap"
	EOS
}

function configure_fcgiwrap_spawn_fcgi() {
  local chroot_dir=$1
  [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  unprevent_daemons_starting ${chroot_dir} spawn-fcgi
  render_fcgiwrap_spawn_fcgi >> ${chroot_dir}/etc/sysconfig/spawn-fcgi
}

##
__BUILD_FCGIWRAP_INCLUDED__=1
