#!/bin/sh

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT

gem_path=/home/wakame/.gem/ruby/1.8/gems
wakame_vdc_version=10.11.0
dcmgr_dbname=wakame_dcmgr
dcmgr_dbuser=root
webui_dbname=wakame_dcmgr_gui
webui_dbpass=passwd
web_api_uri=http://localhost:9001/



# wakame-vdc installation
echo "#Setting up wakame-vdc ..."
{
cat <<'EOS'
wakame_vdc_version=10.11.0

gem_pkgs="
 i18n=0.4.2
 mail=2.2.10
 wakame-vdc-agents=${wakame_vdc_version}
 wakame-vdc-dcmgr=${wakame_vdc_version}
 wakame-vdc-webui=${wakame_vdc_version}
"

for gem_pkg in ${gem_pkgs}; do
  gempkg_name=${gem_pkg%%=*}
  gempkg_ver=${gem_pkg##*=}

  gem list | grep -q -w ${gempkg_name} || {
    gem install ${gempkg_name} --no-rdoc --no-ri -v ${gempkg_ver}
  }
done
EOS
} | su - wakame -c /bin/bash


# wakame system configuration
[ -d /home/wakame/vdc ] || {
  su - wakame -c "mkdir /home/wakame/vdc"
}


echo "# Generate dcmgr/config/dcmgr.conf ..."
cp -p ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config/dcmgr.conf.example ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config/dcmgr.conf

#cat <<EOS > ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config/dcmgr.conf
#database_url "mysql://localhost/${dcmgr_dbname:-dcmgr}?user=${dcmgr_dbuser:-root}"
#amqp_server_uri 'amqp://localhost/'
#create_volume_max_size '10240'
#create_volume_min_size  '1024'
#EOS
chown wakame:wakame ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config/dcmgr.conf

[ -L ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/dcmgr.conf ] || {
  ln -s -f ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config/dcmgr.conf ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/dcmgr.conf
}
chown wakame:wakame ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/dcmgr.conf

[ -L ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/conf ] || {
  ln -s ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/config ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}/conf
}

echo "# Generate dcmgr/config/hva.conf ..."
#[ -f ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/hva.conf ] || {
  cat <<EOS > ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
config.vm_data_dir = "/var/lib/vm/"

# netfilter
config.enable_ebtables = true
config.enable_iptables = true
EOS
  chown wakame:wakame ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/hva.conf
#}

echo "# Generate dcmgr/config/nsa.conf ..."
#[ -f ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/nsa.conf ] || {
  cat <<EOS > ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/nsa.conf
#------------------------
# Configuration file for nsa.
#------------------------

# path for dnsmaq binary
config.dnsmasq_bin_path='/usr/sbin/dnsmasq'

# network name to distribute dhcp/dns managed by this nsa
config.network_name='network1'
EOS
  chown wakame:wakame ${gem_path}/wakame-vdc-agents-${wakame_vdc_version}/config/nsa.conf
#}

echo "# Generate webui/config/initializers/dcmgr_gui.rb ..."
cat <<EOS > ${gem_path}/wakame-vdc-webui-${wakame_vdc_version}/config/initializers/dcmgr_gui.rb
ActiveResource::Connection.class_eval do
  class << self
    def set_vdc_account_uuid(uuid)
      class_variable_set(:@@vdc_account_uuid,uuid)
    end
  end
end

ActiveResource::Base.class_eval do
  self.site = '${web_api_uri:-http://localhost:9001/}'
end

@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env]
Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"
EOS
chown wakame:wakame ${gem_path}/wakame-vdc-webui-${wakame_vdc_version}/config/initializers/dcmgr_gui.rb



echo "# Configure Database for MySQL ..."
yes | mysqladmin -uroot drop ${dcmgr_dbname} >/dev/null 2>&1
yes | mysqladmin -uroot drop ${webui_dbname} >/dev/null 2>&1

cat <<EOS | mysql -uroot
create database ${dcmgr_dbname} default character set utf8;
create database ${webui_dbname} default character set utf8;
grant all on ${webui_dbname}.* to ${webui_dbname}@localhost identified by '${webui_dbpass:-passwd}'
EOS


echo "# Configure Database with rake ..."
{
cat <<EOS
whoami
env
gem environment

cd ${gem_path}/wakame-vdc-dcmgr-${wakame_vdc_version}
pwd
rake db:init

cd ${gem_path}/wakame-vdc-webui-${wakame_vdc_version}
pwd
rake db:init
rake db:sample_data
EOS
} | su - wakame -c /bin/bash



exit 0
