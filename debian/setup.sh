#!/usr/bin/env bash
#

# enable only when debug the script
#set -e

prefix_path=/usr/share/axsh/wakame-vdc
builder_path=${prefix_path}/tests/builder
tmp_path=${prefix_path}/tmp
. $builder_path/functions.sh

[[ -f "/etc/lsb-release" ]] && . /etc/lsb-release

ipaddr=$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $7}')

account_id=a-shpoolxx
#account_id=a-00000000

auth_port=3000
auth_bind=127.0.0.1

webui_port=9000
webui_bind=0.0.0.0

api_port=9001
api_bind=127.0.0.1

metadata_port=9002
metadata_bind=${ipaddr}

proxy_port=8080
proxy_bind=127.0.0.1

ports="${auth_port} ${webui_port} ${api_port} ${metadata_port}"

# networks table
ipv4_gw="${ipv4_gw:-$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $3}')}"
prefix_len="${prefix_len:-$(/sbin/ip route show | awk '$9 == ip { sub(/.*\//, "", $1); print $1; }' ip=$ipaddr)}"

dns_server=${dns_server:-${ipaddr}}
dhcp_server=${dhcp_server:-${ipaddr}}
metadata_server=${metadata_server:-${ipaddr}}
sta_server=${sta_server:-${ipaddr}}

# local store demo machine image
local_store_path="$tmp_path/images"

# virtual machine
vmdir_path=${tmp_path}/instances

vmimage_uuid=lucid0
vmimage_file=${vmimage_uuid}.qcow2
vmimage_s3="http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz"

# mysql
dcmgr_dbname=wakame_dcmgr
dcmgr_dbuser=root
webui_dbname=wakame_dcmgr_gui
webui_dbpass=passwd

hypervisor=kvm

# how many agents?
hva_num=1
sta_num=1

# used resource file
demo_resource=${demo_resource:-'demo_data_setup.sh'}

#Take care of the gem dependencies
cd ${prefix_path}
gem install bundler.gem

# work around if this runs under the bundler container.
[[ -n "$BUNDLE_BIN_PATH" ]] && {
  export RUBYOPT="$RUBYOPT -rubygems"
  alias bundle="$BUNDLE_BIN_PATH"
}
# add bin path to $GEM_HOME/bin.
which gem >/dev/null 2>&1 && {
  export PATH="$(ruby -rubygems -e 'puts Gem.bindir'):$PATH"
} || :

cd ${prefix_path}/dcmgr
bundle install --local

cd ${prefix_path}/frontend/dcmgr_gui
bundle install --local

alias rake="bundle exec rake"
shopt -s expand_aliases

function init_db() {
  dbnames="wakame_dcmgr wakame_dcmgr_gui"
  for dbname in ${dbnames}; do
    mysqladmin -uroot create ${dbname}
  done

  cd ${prefix_path}/dcmgr
  rake db:init

  cd ${prefix_path}/frontend/dcmgr_gui
  rake db:init db:sample_data admin:generate_i18n oauth:create_table

  echo ... rake oauth:create_consumer[${account_id}]
  local oauth_keys=$(rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
  eval ${oauth_keys}

  cat <<EOS > ./oauth_client.rb
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup(:default)
rescue Exception
end

require 'oauth'

consumer_key = "${consumer_key}"
secret_key = "${secret_key}"
site = "http://${proxy_bind:-127.0.0.1}:${proxy_port}"
consumer = OAuth::Consumer.new(consumer_key,secret_key, {:site=>site, :version=>'1.0'})
req = "/api/security_groups"
res = consumer.request(:get, req, nil, {}, {'X-VDC-ACCOUNT-UUID' => '${account_id}'})
p res.body
EOS
  chmod +x ./oauth_client.rb

  # generate demo data
  work_dir=$prefix_path
  builder_script=$demo_resource
  
  # run script in subshell to inherit variables.
  ( 
    [[ -f $work_dir/common.sh ]] && {
      . $work_dir/common.sh
    }
    . $work_dir/$builder_script
  ) || abort "Failed to run $builder_script"
  
}

init_db
sleep 1

#Setup wakame's network
echo "Network setup"
${prefix_path}/network_setup.sh

echo "Setup completed"
exit 0    
