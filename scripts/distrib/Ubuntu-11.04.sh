#!/bin/sh

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

distrib_dir="${distrib_path}/distrib/${DISTRIB_ID}-$DISTRIB_RELEASE}.d"
export LANG=C
# core packages
deb_pkgs="
 ebtables iptables ipset ethtool vlan
 openssh-server openssh-client
 ruby ruby-dev libopenssl-ruby1.8
 rdoc1.8 irb1.8
 g++
 curl libcurl4-openssl-dev
 mysql-server mysql-client libmysqlclient16-dev
 rabbitmq-server
 qemu-kvm kvm-pxe iptables ebtables ubuntu-vm-builder
 dnsmasq
 open-iscsi open-iscsi-utils
 nginx
 libxml2-dev  libxslt1-dev
 ipcalc
 dosfstools
"
# apache2 apache2-threaded-dev libapache2-mod-passenger
# Pick them from natty as obsolete version is in LTS.
natty_deb_pkgs="
 lxc/natty-updates
 rubygems/natty
 rubygems1.8/natty
"

oneiric_deb_pkgs="
 tgt/oneiric
"

function do_install {
  # host configuration
  hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
  egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo 127.0.0.1 $(hostname) >> /etc/hosts

  #  some packages use ubuntu-natty. ex. lxc
  echo $(dirname $0)
  #echo builder_path:${builder_path}
  if [ -d $distrib_dir ]; then
    pushd $distrib_dir
  
    for ubuntu in ubuntu-*; do
     [ -d ${ubuntu} ] || continue
     cd ${ubuntu} && make && cd -
    done
    popd
  fi
  
  # debian packages
  apt-get update
  apt-get -y upgrade
  apt-get -y install ${deb_pkgs}
  apt-get -y --force-yes install ${natty_deb_pkgs}
  apt-get -y --force-yes install ${oneiric_deb_pkgs}

  # update rubygems
  REALLY_GEM_UPDATE_SYSTEM=true gem update --system
}
