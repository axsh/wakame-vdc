#!/usr/bin/env bash
#

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
builder_path=${prefix_path}/tests/builder
tmp_path=${prefix_path}/tmp
vmdir_paht=$tmp_path}/vm
screenrc_path=${tmp_path}/screenrc

. $builder_path/functions.sh

[[ -f "/etc/lsb-release" ]] && . /etc/lsb-release

DISTRIB_ID=$(echo "${DISTRIB_ID:-ubuntu}" | tr 'A-Z' 'a-z')
[ -d ${builder_path}/${DISTRIB_ID}/${DISTRIB_RELEASE} ] || {
  DISTRIB_RELEASE=$(ls -d ${builder_path}/${DISTRIB_ID}/* | tail -1)
  [ -z ${DISTRIB_RELEASE} ] && abort "Cannot detect your using distribution."
  DISTRIB_RELEASE=$(basename ${DISTRIB_RELEASE})
}

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
prefix=$(/sbin/ip route show | awk '$9 == ip { sub(/.*\//, "", $1); print $1; }' ip=$ipaddr)

dns_server=${ipaddr}
dhcp_server=${ipaddr}
metadata_server=${ipaddr}

# local store demo machine image 
local_store_path="$tmp_path/images"

vmimage_uuid=lucid0
vmimage_file=${vmimage_uuid}.qcow2
vmimage_s3="http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz"

#
# build option params
#
# via https://gist.github.com/368215
opts=""
# extract opts
for arg in $*; do
  case ${arg} in
    --*=*)
      key=${arg%%=*}; key=${key##--}
      value=${arg##--*=}
      eval ${key}=${value}
      opts="${opts} ${key}"
      ;;
  esac
done
unset opts
mode=$1

#
# main
#
cleanup

case ${mode} in
  install)
    setup_base
    exit 0;
    ;;
  *)
    ;;
esac


sudo /etc/init.d/rabbitmq-server status && sudo /etc/init.d/rabbitmq-server stop
[ -f /var/lib/rabbitmq/mnesia/ ] && sudo rm -rf /var/lib/rabbitmq/mnesia/
sudo /etc/init.d/rabbitmq-server start

echo $PATH | grep "`gem environment gemdir`/bin" > /dev/null || { 
  export PATH="$(gem environment gemdir)/bin:$PATH"
}

alias rake="bundle exec rake"
dbnames="wakame_dcmgr wakame_dcmgr_gui"
for dbname in ${dbnames}; do
  yes | mysqladmin -uroot drop   ${dbname}
        mysqladmin -uroot create ${dbname}
done


echo ... cd ${prefix_path}/dcmgr
cd ${prefix_path}/dcmgr
tasks="db:init"
for task in ${tasks}; do
  echo ... rake ${task}
           rake ${task}
done


cd ${prefix_path}/frontend/dcmgr_gui
# db
tasks="
 db:init
 db:sample_data
 oauth:create_table
 admin:generate_i18n
"
for task in ${tasks}; do
  echo ... rake ${task}
           rake ${task}
done


echo ... rake oauth:create_consumer[${account_id}]
oauth_keys=$(rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
eval ${oauth_keys}
unset oauth_keys

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
req = "/api/netfilter_groups"
res = consumer.request(:get, req, nil, {}, {'X-VDC-ACCOUNT-UUID' => '${account_id}'})
p res.body
EOS
chmod +x ./oauth_client.rb


# generate demo data
run_builder "91_generate-demo-resource.sh"
sleep 1

# screen
cd ${prefix_path}
echo "Creating screen windows... wait 5 seconds."

# screen configuration file
/bin/cat <<EOS > $screenrc_path
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<" 
defscrollback 10000
logfile ${tmp_path}/screenlog.%t
logfile flush 1
EOS

cd ${prefix_path}
screen -L -d -m -S vdc -t vdc -c $screenrc_path || abort "Failed to start new screen session"
screen_it collector "cd ${prefix_path}/dcmgr/; ./bin/collector | tee ${tmp_path}/vdc-collector.log;"
screen_it nsa       "cd ${prefix_path}/dcmgr; sudo ./bin/nsa -i demo1 | tee ${tmp_path}/vdc-nsa.log;"
screen_it hva       "cd ${prefix_path}/dcmgr; sudo ./bin/hva -i demo1 | tee ${tmp_path}/vdc-hva.log;"
screen_it metadata  "cd ${prefix_path}/dcmgr/web/metadata; bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru | tee ${tmp_path}/vdc-metadata.log;"
screen_it api       "cd ${prefix_path}/dcmgr/web/api;      bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru | tee ${tmp_path}/vdc-api.log;"
screen_it auth      "cd ${prefix_path}/frontend/dcmgr_gui; bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru | tee ${tmp_path}/vdc-auth.log;"
screen_it proxy     "sudo ${builder_path}/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${builder_path}/conf/proxy.conf"
screen_it webui     "cd ${prefix_path}/frontend/dcmgr_gui/config; bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru | tee ${tmp_path}/vdc-webui.log;"
screen_it test      "echo Enjoy wakame-vdc.; echo \* http://${ipaddr}:${webui_port}/; cd ${prefix_path}/frontend/dcmgr_gui; ./oauth_client.rb; "
screen -S vdc -x


#
cleanup


exit 0
