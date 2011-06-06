#!/bin/sh

home_dir=/home/wakame
work_dir=${home_dir}/work


#
# packages
#

# debian packages
deb_pkgs="
 git
 git-core
 screen
"

# ruby gems packages
gem_pkgs="
 bundler
 rake
 rack
"

#
# install
#
sudo apt-get -y install ${deb_pkgs}

for gem_pkg in ${gem_pkgs}; do
  gem list | egrep -q -w ${gem_pkg} || {
    gem install ${gem_pkg} --no-ri --no-rdoc
  }
done


[ -d ${work_dir} ] || mkdir ${work_dir}
cd ${work_dir}

#[ -d wakame-vdc  ] || git clone git://github.com/axsh/wakame-vdc.git
#[ -d gist-895965 ] || git clone git://gist.github.com/895965.git gist-895965
#
#cp -f ${work_dir}/gist-895965/vdc.sh ./wakame-vdc/.
#chmod +x ./wakame-vdc/vdc.sh

#cd ${work_dir}/wakame-vdc
#[ -f Makefile ] || \
#  wget --no-check-certificate https://github.com/hansode/wakame-vdc2-builder/raw/11.04/ubuntu/10.04/Makefile


bundle_update() {
  dir=$1

  [ -d $dir ] || exit 1
  cd $dir

  [ -d vendor/bundle ] && rm -rf vendor/bundle
  [ -d .bundle ] || mkdir .bundle
  cat <<EOS > .bundle/config
BUNDLE_DISABLE_SHARED_GEMS: "1" 
BUNDLE_WITHOUT: "" 
BUNDLE_PATH: vendor/bundle
EOS

  #bundle update
  echo "... bundle install"
  pwd
  bundle install
}

bundle_update ${work_dir}/wakame-vdc/dcmgr/
bundle_update ${work_dir}/wakame-vdc/frontend/dcmgr_gui/


# screen configuration file
cat <<EOS > ${home_dir}/.screenrc
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<" 
defscrollback 10000
EOS


# prepare configuration files

# dcmgr
cd ${work_dir}/wakame-vdc/dcmgr/config/
cp -f dcmgr.conf.example dcmgr.conf

cat <<EOS > hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
#config.vm_data_dir = "/home/demo/vm" 
config.vm_data_dir = "/var/lib/vm" 

# netfilter
config.enable_ebtables = true
config.enable_iptables = true
#config.enable_ebtables = false
#config.enable_iptables = false

config.verbose_netfilter = true
EOS


cat <<EOS  > nsa.conf
#------------------------
# Configuration file for nsa.
#------------------------

# path for dnsmaq binary
config.dnsmasq_bin_path='/usr/sbin/dnsmasq'

# network name to distribute dhcp/dns managed by this nsa
config.network_name='nw-demonet'

config.logging = true
EOS



# frontend
cd ${work_dir}/wakame-vdc/frontend/dcmgr_gui/config/
cp -f dcmgr_gui.yml.example dcmgr_gui.yml



exit 0
