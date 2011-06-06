#!/usr/bin/env bash
#

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
builder_path=${prefix_path}/tests/builder
switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
ipaddr=$(/sbin/ip addr show ${switch} | grep -w inet | awk '{print $2}')
myaddr=${ipaddr%%/*}

dist=ubuntu
dist_ver=

account_id=a-shpoolxx
#account_id=a-00000000

auth_port=3000
auth_bind=127.0.0.1

webui_port=9000
webui_bind=0.0.0.0

api_port=9001
api_bind=127.0.0.1

metadata_port=9002
metadata_bind=${myaddr}

proxy_port=8080
proxy_bind=127.0.0.1

ports="${auth_port} ${webui_port} ${api_port} ${metadata_port}"

NL=`echo -ne '\015'`


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


#
# local functions
#
function screen_it {
  screen -S vdc -X screen -t $1
  screen -S vdc -p $1 -X stuff "$2$NL"
}

function build_builder_path {
  if [ -z "${dist_ver}" ]; then
    builder_dist_path=$(for i in ${builder_path}/${dist}/*; do [ -d  ${i} ] || continue; echo $i; done | tail -1)
  else
    builder_dist_path=${builder_path}/${dist}/${dist_ver}
  fi

  [ -d ${builder_dist_path} ] || {
    echo no such directory: ${builder_dist_path} >&2
    exit 1
  }

  echo ${builder_dist_path}
}

function setup_base {
  cd $(build_builder_path)
  [ -f Makefile ] || exit 1

  #make clean
  make developer
}

function update_vdc {
  cd ${prefix_path}
  git pull
}

function cleanup {
  screen -S vdc -X quit

  sudo killall dnsmasq
  sudo killall kvm

  [ -f /var/run/wakame-proxy.pid ] && \
    sudo nginx -s stop -c${prefix_path}/frontend/dcmgr_gui/config/proxy.conf

  for component in collector nsa hva; do
    pid=$(ps awwx | egrep "[b]in/${component}" | awk '{print $1}')
    [ -z "${pid}" ] || sudo kill ${pid}
  done

  for port in ${ports}; do
    pid=$(ps awwx | egrep "[r]ackup -p ${port}" | awk '{print $1}')
    [ -z "${pid}" ] || sudo kill -9 ${pid}
  done

  # netfilter
  sudo ebtables --init-table
  for table in nat filter; do
    for xcmd in F Z X; do
      sudo iptables -t ${table} -${xcmd}
    done
  done

  [ -f ${prefix_path}/frontend/dcmgr_gui/log/proxy_access.log ] && \
    echo ": > ${prefix_path}/frontend/dcmgr_gui/log/proxy_access.log" | sudo /bin/sh
}


#
# main
#
cleanup

case ${mode} in
  integrate)
    update_vdc
    setup_base
    ;;
  update)
    update_vdc
    ;;
  *)
    ;;
esac


sudo /etc/init.d/rabbitmq-server stop
[ -f /var/lib/rabbitmq/mnesia/ ] && sudo rm -rf /var/lib/rabbitmq/mnesia/
sudo /etc/init.d/rabbitmq-server start


dbnames="wakame_dcmgr wakame_dcmgr_gui"
for dbname in ${dbnames}; do
  yes | mysqladmin -uroot drop   ${dbname}
        mysqladmin -uroot create ${dbname}
done


echo ... cd ${prefix_path}/dcmgr
cd ${prefix_path}/dcmgr
tasks=db:init
for task in ${tasks}; do
  echo ... bundle exec rake ${task}
           bundle exec rake ${task}
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
  echo ... bundle exec rake ${task}
           bundle exec rake ${task}
done

echo ... bundle exec rake oauth:create_consumer[${account_id}]
oauth_keys=$(bundle exec rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
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
# api
rake api:create_proxy_config


# gemerate demo data
cd $(build_builder_path)
make demo
sleep 1

ls ./z*_*.sh 2>/dev/null && {
  for zscript in ./z*_*.sh; do
    echo ... ${zscript}
    ${zscript}
  done
}
sleep 3


# screen
cd ${prefix_path}
echo "Creating screen windows... wait 5 seconds."

screen -d -m -S vdc -t vdc
screen_it collector "cd ${prefix_path}/dcmgr/; ./bin/collector;"
sleep 2
screen_it nsa       "cd ${prefix_path}/dcmgr; sudo ./bin/nsa | tee /tmp/vdc-nsa.log;"
screen_it hva       "cd ${prefix_path}/dcmgr; sudo ./bin/hva | tee /tmp/vdc-hva.log;"
screen_it metadata  "cd ${prefix_path}/dcmgr/web/metadata; bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru | tee /tmp/vdc-metadata.log;"
screen_it api       "cd ${prefix_path}/dcmgr/web/api;      bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru | tee /tmp/vdc-api.log;"
screen_it auth      "cd ${prefix_path}/frontend/dcmgr_gui; bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru | tee /tmp/vdc-auth.log;"
sleep 1
screen_it proxy     "sudo nginx -c ${prefix_path}/frontend/dcmgr_gui/config/proxy.conf; tail -F ${prefix_path}/frontend/dcmgr_gui/log/proxy_access.log | tee /tmp/vdc-proxy.log"
sleep 1
screen_it webui     "cd ${prefix_path}/frontend/dcmgr_gui/config; bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru | tee /tmp/vdc-webui.log;"
screen_it test      "echo Enjoy wakame-vdc.; echo \* http://${myaddr}:${webui_port}/; cd ${prefix_path}/frontend/dcmgr_gui; ./oauth_client.rb; "
screen -S vdc -x


#
cleanup


exit 0
