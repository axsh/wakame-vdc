#!/bin/bash

set -e

work_dir=${work_dir:?"work_dir needs to be set"}
builder_path=${builder_path:?"builder_path needs to be set"}


#
# MySQL
#
#dcmgr_dbname=wakame_dcmgr
#dcmgr_dbuser=root
#webui_dbname=wakame_dcmgr_gui
#webui_dbpass=passwd

echo "# Configure Database for MySQL ..."
echo | mysql -uroot ${dcmgr_dbname} && yes | mysqladmin -uroot drop ${dcmgr_dbname} >/dev/null 2>&1
echo | mysql -uroot ${webui_dbname} && yes | mysqladmin -uroot drop ${webui_dbname} >/dev/null 2>&1

cat <<EOS | mysql -uroot
create database ${dcmgr_dbname} default character set utf8;
create database ${webui_dbname} default character set utf8;
grant all on ${webui_dbname}.* to ${webui_dbname}@localhost identified by '${webui_dbpass:-passwd}'
EOS


#
# packages
#

# debian packages
deb_pkgs="
 git-core
 screen
 tmux
"

# rake was deleted

#
# install
#
DEBIAN_FRONTEND=${DEBIAN_FRONTEND} apt-get -y install ${deb_pkgs}

[ -d ${work_dir} ] || mkdir ${work_dir}
cd ${work_dir}

function bundle_update() {
  local dir=$1

  [ -d $dir ] || exit 1
  # run in subshell to keep cwd.
  (
  cd $dir

  [ -d .vendor/bundle ] && rm -rf .vendor/bundle
  # this oneliner will generate .bundle/config.
  shlog bundle install --path=.vendor/bundle
  )
}

echo "before bundle_update"

bundle_update ${work_dir}/dcmgr/
bundle_update ${work_dir}/frontend/dcmgr_gui/


# prepare configuration files

# dcmgr
cd ${work_dir}/dcmgr/config/
cp -f dcmgr.conf.example dcmgr.conf
cp -f snapshot_repository.yml.example snapshot_repository.yml
#cp -f hva.conf.example hva.conf
cp -f nsa.conf.example nsa.conf
cp -f sta.conf.example sta.conf

# dcmgr:hva
[ -d ${vmdir_path} ] || mkdir $vmdir_path
# perl -pi -e "s,^config.vm_data_dir = .*,config.vm_data_dir = \"${vmdir_path}\"," hva.conf
# TODO: delete generating hva.conf in this script. should copy hva.conf.example to hva.conf
cat <<EOS > hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
config.vm_data_dir = "${vmdir_path}"

# netfilter
config.enable_ebtables = true
config.enable_iptables = true
config.enable_openflow = false

# physical nic index
config.hv_ifindex      = 2 # ex. /sys/class/net/eth0/ifindex => 2

# bridge device name prefix
config.bridge_prefix   = 'br'

# bridge device name novlan
config.bridge_novlan   = 'br0'

# display netfitler commands
config.verbose_netfilter = false
config.verbose_openflow  = false

# netfilter log output flag
config.packet_drop_log = false

# debug netfilter
config.debug_iptables = false

# Use ipset for netfilter
config.use_ipset       = false

# Path for brctl
config.brctl_path = '/usr/sbin/brctl'

# Directory used by Open vSwitch daemon for run files
config.ovs_run_dir = '${work_dir}/ovs/var/run/openvswitch'

# Path for ovs-ofctl
config.ovs_ofctl_path = '${work_dir}/ovs/bin/ovs-ofctl'

# Trema base directory
config.trema_dir = '${work_dir}/trema'
EOS

# frontend
cd ${work_dir}/frontend/dcmgr_gui/config/
cp -f dcmgr_gui.yml.example dcmgr_gui.yml



exit 0
