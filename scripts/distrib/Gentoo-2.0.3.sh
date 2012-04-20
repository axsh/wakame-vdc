#!/bin/bash
#
# Wakame vdc install script for Gentoo
#

# With emerge, check package is exist or not.
function check_package() {
	local pkg_name=$1

	[ -z $pkg_name ] && exit 1

	emerge_output=`emerge -pq ${pkg_name} | sed -ne 's/^\[ebuild *\([A-Za-z]*\) .*/\1/p' | uniq`
	if [ $? = 1 ]; then
		echo "${pkg_name} is not exit in portage!"
		echo "exit."
		exit 0
	fi

	#echo "XX:${emerge_output}"
	if [ "${emerge_output}" != 'N' ]; then
		echo "${pkg_name} is already installed!"
		return 1
	fi
	echo "${pkg_name} is not installed!"
	return 0
}

function install_dist_package {
  # Check required packages and install it if missing.
  # Note: MySQL is checked later.
  required_pkgs='git dev-lang/ruby rubygems rabbitmq-server nginx 
  		ebtables iptables ethtool vconfig curl openssl 
  		dnsmasq libxml2 libxslt erlang qemu-kvm dosfstools 
  		ipcalc tmux app-misc/screen iproute2 
  		open-iscsi' # iscsitarget"
  
  echo "Checking required package"
  for i in ${required_pkgs}; do 
  	echo "check package for $i"
  	check_package $i
  	#echo "X:$?"
  	if [ "$?" -eq "0" ]; then
  		emerge $i
  	fi
  done
  
  check_package mysql
  if [ "$?" -eq "0" ]; then
  	emerge mysql
  	echo "Setup MySQL DB"
  	rc-update add mysql default
  	/usr/bin/mysql_install_db
  	/etc/init.d/mysql start
  	echo "Setup MySQL DB done!"
  fi

  # Update gem
  gem update --system
}

# 
# main 
#
function do_install {
  install_dist_package
}
