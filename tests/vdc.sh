#!/usr/bin/env bash
#

# enable only when debug the script
#set -e

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
builder_path=${prefix_path}/tests/builder
tmp_path=${prefix_path}/tmp
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
ci_archive_dir=$prefix_path/../results


#
without_bundle_install=
without_quit_screen=
without_after_cleanup=

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

# work around if this runs under the bundler container.
[[ -n "$BUNDLE_BIN_PATH" ]] && {
  export RUBYOPT="$RUBYOPT -rubygems"
  alias bundle="$BUNDLE_BIN_PATH"
}
# add bin path to $GEM_HOME/bin.
which gem >/dev/null 2>&1 && {
  export PATH="$(ruby -rubygems -e 'puts Gem.bindir'):$PATH"
} || :

alias rake="bundle exec rake"
shopt -s expand_aliases

function run_standalone() {
  # forece reset and restart rabbitmq
  /etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  [ -f /var/lib/rabbitmq/mnesia/ ] && rm -rf /var/lib/rabbitmq/mnesia/
  /etc/init.d/rabbitmq-server start

  dbnames="wakame_dcmgr wakame_dcmgr_gui"
  for dbname in ${dbnames}; do
    yes | mysqladmin -uroot drop   ${dbname}
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
req = "/api/netfilter_groups"
res = consumer.request(:get, req, nil, {}, {'X-VDC-ACCOUNT-UUID' => '${account_id}'})
p res.body
EOS
  chmod +x ./oauth_client.rb


  # generate demo data
  work_dir=$prefix_path
  run_builder "91_generate-demo-resource.sh"
  sleep 1

  # screen
  cd ${prefix_path}
  echo "Creating screen windows..."

  # screen configuration file
  /bin/cat <<EOS > $screenrc_path
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<" 
defscrollback 10000
logfile ${tmp_path}/screenlog.%t
logfile flush 1
EOS

  screen -L -d -m -S vdc -t vdc -c $screenrc_path || abort "Failed to start new screen session"
  screen_it collector "cd ${prefix_path}/dcmgr/ && ./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
  screen_it nsa       "cd ${prefix_path}/dcmgr/ && ./bin/nsa -i demo1 2>&1 | tee ${tmp_path}/vdc-nsa.log"
  screen_it hva       "cd ${prefix_path}/dcmgr/ && ./bin/hva -i demo1 2>&1 | tee ${tmp_path}/vdc-hva.log"
  screen_it metadata  "cd ${prefix_path}/dcmgr/web/metadata && bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
  screen_it api       "cd ${prefix_path}/dcmgr/web/api      && bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru 2>&1 | tee ${tmp_path}/vdc-api.log"
  screen_it auth      "cd ${prefix_path}/frontend/dcmgr_gui && bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"
  screen_it proxy     "${builder_path}/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${builder_path}/conf/proxy.conf"
  screen_it webui     "cd ${prefix_path}/frontend/dcmgr_gui/config && bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"
  [ "${sta_server}" = "${ipaddr}" ] && \
  screen_it sta       "cd ${prefix_path}/dcmgr/ && ./bin/sta -i demo1 2>&1 | tee ${tmp_path}/vdc-sta.log"


  retry 10 <<EOF || abort "Can't see dcmgr"
echo > "/dev/tcp/${api_bind}/${api_port}"
EOF
  retry 10 <<EOF || abort "Can't see nginx"
echo > "/dev/tcp/localhost/8080"
EOF
}

function run_developer() {
  run_standalone
  screen_it test "echo Enjoy wakame-vdc.; echo \* http://${ipaddr}:${webui_port}/; cd ${prefix_path}/frontend/dcmgr_gui; ./oauth_client.rb; "
  # attach the shell.
  screen -S vdc -x
}


function run_standalone_integration_test {
  cd $prefix_path/tests/spec
  [ -z "${without_bundle_install}" ] && bundle install

  for i in {0..5}; do
    echo sleep 5 ... ${i}
    sleep 5
    uptime
  done

  # run integrate test specs. 
  bundle exec rspec . 

  return $?
}


function ci_post_process {
  local sig=$1
  local ci_result=$2

  # make log archive and save to archiving folder.
  [[ -d $ci_archive_dir ]] && {
    cd $prefix_path
    tar cf "${sig}.tar" ./tmp/screenlog.*
    mv ${sig}.tar $ci_archive_dir
  }

}

#
# main
#

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

cleanup

excode=0
case ${mode} in
  install)
    setup_base
    ;;
  standalone:ci)
    # disable shell exit on error which caused by test cases.
    set +e
    (
     run_standalone
     run_standalone_integration_test
    )
    excode=$?
    set -e
    [ -z "${without_quit_screen}" ] && screen -S vdc -X quit
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  *)
    run_developer
    ;;
esac

#
[ -z "${without_after_cleanup}" ] && cleanup


exit $excode
