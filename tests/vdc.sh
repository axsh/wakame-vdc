#!/usr/bin/env bash
#

set -e

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

[[ -f /etc/redhat-release ]] && {
  DISTRIB_ID=rhel
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

# dhcp range for demo1
range_begin=${range_begin}
range_end=${range_end}

# local store demo machine image
local_store_path="$tmp_path/images"

# virtual machine
vmdir_path=${tmp_path}/instances

vmimage_uuid=lucid0
vmimage_file=${vmimage_uuid}.qcow2
vmimage_s3="http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz"
vmimage_arch=32

# mysql
dcmgr_dbname=wakame_dcmgr
dcmgr_dbuser=root
webui_dbname=wakame_dcmgr_gui
webui_dbpass=passwd

hypervisor=kvm
ci_archive_dir=$prefix_path/../results

with_openflow=no

#
without_bundle_install=
without_quit_screen=
without_screen=

# screen mode: screen, tmux, bg
screen_mode=${screen_mode:-'screen'}

# how many agents?
hva_num=1
sta_num=1

# used resource file
demo_resource=${demo_resource:-'91_generate-demo-resource.sh'}

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

function init_db() {
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
req = "/api/security_groups"
res = consumer.request(:get, req, nil, {}, {'X-VDC-ACCOUNT-UUID' => '${account_id}'})
p res.body
EOS
  chmod +x ./oauth_client.rb

  # generate demo data
  work_dir=$prefix_path
  run_builder ${demo_resource}
}

function run_standalone() {
  # forece reset and restart rabbitmq
  /etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  [ -f /var/lib/rabbitmq/mnesia/ ] && rm -rf /var/lib/rabbitmq/mnesia/
  /etc/init.d/rabbitmq-server start

  [[ -x /etc/init.d/tgt ]] && { initctl restart tgt; }

  init_db
  sleep 1

  # screen
  cd ${prefix_path}

  [ -z "${without_screen}" ] && {
    screen_open || abort "Failed to start new screen session"
    screen_it collector "cd ${prefix_path}/dcmgr/ && ./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
    screen_it nsa       "cd ${prefix_path}/dcmgr/ && ./bin/nsa -i demo1 2>&1 | tee ${tmp_path}/vdc-nsa.log"

    for i in $(seq 1 ${hva_num}); do
      screen_it hva${i} "cd ${prefix_path}/dcmgr/ && ./bin/hva -i demo${i} 2>&1 | tee ${tmp_path}/vdc-hva${i}.log"
    done

    screen_it metadata  "cd ${prefix_path}/dcmgr/web/metadata && bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
    screen_it api       "cd ${prefix_path}/dcmgr/web/api      && bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru 2>&1 | tee ${tmp_path}/vdc-api.log"
    screen_it auth      "cd ${prefix_path}/frontend/dcmgr_gui && bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"
    screen_it proxy     "${builder_path}/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${builder_path}/conf/proxy.conf"
    screen_it webui     "cd ${prefix_path}/frontend/dcmgr_gui/config && bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"
    [ "${sta_server}" = "${ipaddr}" ] && {
      for i in $(seq 1 ${sta_num}); do
        screen_it sta${i} "cd ${prefix_path}/dcmgr/ && ./bin/sta -i demo${i} 2>&1 | tee ${tmp_path}/vdc-sta${i}.log"
      done
    }
    [ "${with_openflow}" != "yes" ] || \
    screen_it ofc       "cd ${prefix_path}/dcmgr/ && ./bin/ofc -i demo1"
  }  || {
    cd ${prefix_path}/dcmgr/ && run2bg "./bin/collector > ${tmp_path}/vdc-collector.log 2>&1"
    cd ${prefix_path}/dcmgr/ && run2bg "./bin/nsa -i demo1 > ${tmp_path}/vdc-nsa.log 2>&1"

    for i in $(seq 1 ${hva_num}); do
      cd ${prefix_path}/dcmgr/ && run2bg "./bin/hva -i demo${i} > ${tmp_path}/vdc-hva${i}.log 2>&1"
    done

    cd ${prefix_path}/dcmgr/web/metadata && run2bg "bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru > ${tmp_path}/vdc-metadata.log 2>&1"
    cd ${prefix_path}/dcmgr/web/api      && run2bg "bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru > ${tmp_path}/vdc-api.log 2>&1"
    cd ${prefix_path}/frontend/dcmgr_gui && run2bg "bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru > ${tmp_path}/vdc-auth.log 2>&1"
    run2bg "${builder_path}/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${builder_path}/conf/proxy.conf"
    cd ${prefix_path}/frontend/dcmgr_gui/config && run2bg "bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru > ${tmp_path}/vdc-webui.log 2>&1"
    [ "${sta_server}" = "${ipaddr}" ] && {
      for i in $(seq 1 ${sta_num}); do
        cd ${prefix_path}/dcmgr/ && run2bg "./bin/sta -i demo${i} > ${tmp_path}/vdc-sta${i}.log 2>&1"
      done
    }
    [ "${with_openflow}" != "yes" ] || {
      cd ${prefix_path}/dcmgr/ && run2bg "./bin/ofc -i demo1"
    }
    #wait_jobs
    echo "${pids}" > ${tmp_path}/vdc-pid.log
    shlog ps -p ${pids}
  }

}

function run_multiple() {
  # forece reset and restart rabbitmq
  /etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  [ -f /var/lib/rabbitmq/mnesia/ ] && rm -rf /var/lib/rabbitmq/mnesia/
  /etc/init.d/rabbitmq-server start

  [[ -x /etc/init.d/tgt ]] && { initctl restart tgt; }

  demo_resource="92_generate-demo-resource.sh"
  init_db
  sleep 1

  for h in ${host_nodes}; do
      [ "${h}" = "${ipaddr}" ] || {
	  cat <<EOF | ssh ${h}
[ -d ${prefix_path} ] || mkdir -p ${prefix_path}
rsync -avz -e ssh ${ipaddr}:${prefix_path}/ ${prefix_path}
EOF
      }
  done

  for s in ${storage_nodes}; do
      [ "${s}" = "${ipaddr}" ] || {
      cat <<EOF | ssh ${s}
[ -d ${prefix_path} ] || mkdir -p ${prefix_path}
rsync -avz -e ssh ${ipaddr}:${prefix_path}/ ${prefix_path}
EOF
      }
  done

  # screen
  cd ${prefix_path}

  [ -z "${without_screen}" ] && {
    screen_open || abort "Failed to start new screen session"
    screen_it collector "cd ${prefix_path}/dcmgr/ && ./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
    screen_it nsa       "cd ${prefix_path}/dcmgr/ && ./bin/nsa -i demo1 2>&1 | tee ${tmp_path}/vdc-nsa.log"

    for h in ${host_nodes}; do
        hvaname=demo$(echo ${h} | sed -e 's/\./ /g' | awk '{print $4}')
        [ "${h}" = "${ipaddr}" ] && {
            screen_it hva.${hvaname} "cd ${prefix_path}/dcmgr/ && ./bin/hva -i ${hvaname} 2>&1 | tee ${tmp_path}/vdc-hva.log"
        } || {
            screen_it hva.${hvaname} "echo \"cd ${prefix_path}/dcmgr/ && ./bin/hva -i ${hvaname} -s amqp://${ipaddr}/ 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh ${h}"
        }
    done

    screen_it metadata  "cd ${prefix_path}/dcmgr/web/metadata && bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
    screen_it api       "cd ${prefix_path}/dcmgr/web/api      && bundle exec rackup -p ${api_port}      -o ${api_bind:-127.0.0.1}      ./config.ru 2>&1 | tee ${tmp_path}/vdc-api.log"
    screen_it auth      "cd ${prefix_path}/frontend/dcmgr_gui && bundle exec rackup -p ${auth_port}     -o ${auth_bind:-127.0.0.1}     ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"
    screen_it proxy     "${builder_path}/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${builder_path}/conf/proxy.conf"
    screen_it webui     "cd ${prefix_path}/frontend/dcmgr_gui/config && bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"

    for s in ${storage_nodes}; do
        staname=demo$(echo ${s} | sed -e 's/\./ /g' | awk '{print $4}')
        [ "${s}" = "${ipaddr}" ] && {
            screen_it sta.${staname} "cd ${prefix_path}/dcmgr/ && ./bin/sta -i ${staname} 2>&1 | tee ${tmp_path}/vdc-sta.log"
        } || {
            screen_it sta.${staname} "echo \"cd ${prefix_path}/dcmgr/ && ./bin/sta -i ${staname} -s amqp://${ipaddr}/ 2>&1 | tee ${tmp_path}/vdc-sta.log\" | ssh ${s}"
        }
    done
  }
}

function check_ready_standalone {
  retry 10 <<'EOF' || abort "Can't see dcmgr"
echo > "/dev/tcp/${api_bind}/${api_port}"
EOF
  retry 10 <<'EOF' || abort "Can't see nginx"
echo > "/dev/tcp/localhost/8080"
EOF

  if [ "${with_openflow}" == "yes" ]; then
      nodes=5
  else
      nodes=4
  fi

  # Wait for until all agent nodes become online.
  retry 10 <<'EOF' || abort "Offline nodes still exist."
sleep 5
[ ${nodes} -eq "`echo "select state from node_states where state='online'" | mysql -uroot wakame_dcmgr | wc -l`" ]
EOF
}

function check_ready_multiple {
  retry 10 <<'EOF' || abort "Can't see dcmgr"
echo > "/dev/tcp/${api_bind}/${api_port}"
EOF
  retry 10 <<'EOF' || abort "Can't see nginx"
echo > "/dev/tcp/localhost/8080"
EOF

  # Wait for until all agent nodes become online.
  node_num=2
  for i in ${host_nodes}; do node_num=`expr ${node_num} + 1`; done
  for i in ${storage_nodes}; do node_num=`expr ${node_num} + 1`; done
  retry 10 <<'EOF' || abort "Offline nodes still exist."
sleep 5
[ ${node_num} -eq "`echo "select state from node_states where state='online'" | mysql -uroot wakame_dcmgr | wc -l`" ]
EOF
}

function ci_post_process {
  local sig=$1
  local ci_result=$2

  [ -z "${without_screen}" ] || return 0

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
    (
     set +e
     run_standalone
     check_ready_standalone
     cd $prefix_path/tests/spec
     [ -z "${without_bundle_install}" ] && bundle install --path=.vendor/bundle
     cp -f config/config.yml.example config/config.yml

     # run integrate test specs.
     bundle exec rspec -fs .
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  standalone:ci:cucumber)
    (
     set +e
     run_standalone
     check_ready_standalone
     cd $prefix_path/tests/cucumber
     [ -z "${without_bundle_install}" ] && bundle install --path=.vendor/bundle
     bundle exec cucumber -r features/ features/1shot/1shot.feature
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  standalone:ci:build_cd)
    # build image
    cd_builder_dir="${prefix_path}/tests/cd_builder"
    build_image_file="ubuntu-10.04.3-server-amd64.iso"
    build_image="/var/tmp/${build_image_file}"
    build_image_source="http://releases.ubuntu.com/lucid/${build_image_file}"
    built_image="${cd_builder_dir}/wakame-vdc-*-amd64.iso"

    ( 
      set +e
      check_ready_standalone

      cd "${cd_builder_dir}"

      # run build iso image.
      [[ ! -e "${build_image}" ]] && { 
        ${prefix_path}/dcmgr/script/pararell-curl.sh --url=${build_image_source} --output_path=$build_image
      }

      if [ -e "${build_image}" ]; then
        ./build_cd.sh --without-gpg-sign ${build_image}
        rm ${built_image}
        
      else
        abort "Couldn't find ${build_image}"
      fi
      
    )
    excode=$?
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  multiple:ci)
    (
     set +e
     . builder/conf/nodes.conf
     cleanup_multiple
     run_multiple
     check_ready_multiple
     cd ${prefix_path}/tests/spec2
     [ -z "${without_bundle_install}" ] && bundle install --path=.vendor/bundle
     bundle exec rspec -fs .
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  init)
    init_db
    ;;
  cleanup)
    ;;
  openflow)
    # interactive mode with OpenFlow
    with_openflow=yes
    run_standalone
    screen_attach
    screen_close
    [ -f "${tmp_path}/vdc-pid.log" ] && {
      wait $(cat ${tmp_path}/vdc-pid.log)
    }
    ;;
  openflow:ci)
    # disable shell exit on error which caused by test cases.
    (
     set +e
     with_openflow=yes
     run_standalone
     check_ready_standalone
     cd $prefix_path/tests/spec
     [ -z "${without_bundle_install}" ] && bundle install

     # run integrate test specs.
     bundle exec rspec -fs .
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  *)
    # interactive mode
    run_standalone
    screen_attach
    screen_close
    [ -f "${tmp_path}/vdc-pid.log" ] && {
      wait $(cat ${tmp_path}/vdc-pid.log)
    }
    ;;
esac

#
[ -f "${tmp_path}/vdc-pid.log" ] && {
  pids=$(cat ${tmp_path}/vdc-pid.log)
  [ -z "${pids}" ] || {
    for pid in ${pids}; do
      ps -p ${pid} >/dev/null 2>&1 && kill -HUP  ${pid}
    done
  }
}

exit $excode
