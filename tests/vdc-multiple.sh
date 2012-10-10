#!/usr/bin/env bash
# Developer Shell for Wakame VDC.

set -e

abs_path=$(cd $(dirname $0) && pwd)
data_path=$(cd "vdc.sh.d" && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
VDC_ROOT=$prefix_path
tmp_path=$VDC_ROOT/tmp
screenrc_path=${tmp_path}/screenrc

# screen mode: screen, tmux, bg
screen_mode=${screen_mode:-'screen'}

PATH="${VDC_ROOT}/ruby/bin:$PATH"
export PATH VDC_ROOT

. ${abs_path}/builder/functions.sh
. ${data_path}/config.env

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

function cleanup {
  set +e
  screen -ls vdc | egrep -q vdc && {
    screen -S vdc -X quit
  } || :

  ps -ef | egrep 'bin/[d]nsmasq' -q && {
    killall dnsmasq
  } || :

  /sbin/iscsiadm -m node -u
  ps -ef | egrep '[t]gtd' -q && {
    /usr/sbin/tgt-admin --dump | grep ^\<target | awk '{print $2}' | sed 's,>$,,' | while read iqn; do echo ... ${iqn}; /usr/sbin/tgt-admin --delete ${iqn}; done
    initctl stop tgt
  } || :

  ps -ef | egrep 'bin/[k]vm' -q && {
    killall kvm
  } || :

  for i in $(lxc-ls); do
    echo ... ${i}
    lxc-destroy -n ${i} || lxc-kill -n ${i}
  done
  # clean loop mount
  mount | egrep "$tmp_path/instances" | awk '{print $3}' | while read i;do
    echo "umount loop mount path: ${i}"
    umount ${i}
  done


  for i in collector nsa hva sta; do
    pid=$(ps awwx | egrep "[b]in/$i" | awk '{print $1}')
    [ -z "${pid}" ] || kill -9 ${pid}
  done

  #for port in ${ports}; do
  #  pid=$(ps awwx | egrep "[r]ackup -p ${port}" | awk '{print $1}')
  #  [ -z "${pid}" ] || kill -9 ${pid}
  #done

  # Clear netfilter
  ebtables --init-table > /dev/null
  for table in nat filter; do
    for xcmd in F Z X; do
      iptables -t ${table} -${xcmd} > /dev/null
    done
  done

  [[ -d ${VDC_ROOT}/frontend/dcmgr_gui/log/ ]] && {
    [[ -f ${VDC_ROOT}/frontend/dcmgr_gui/log/proxy_access.log ]] || : && \
      echo ": > ${VDC_ROOT}/frontend/dcmgr_gui/log/proxy_access.log" | /bin/sh
  } || :

  # logfile
  rm -f $tmp_path/*.log $tmp_path/screenlog.*

  rm -rf ${tmp_path}/volumes/vol-* ${tmp_path}/snap/* ${tmp_path}/instances/i-*

  # force reset and restart rabbitmq
  /etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  [[ -f /var/lib/rabbitmq/mnesia/ ]] && rm -rf /var/lib/rabbitmq/mnesia/
  /etc/init.d/rabbitmq-server start

  (initctl status tgt | grep stop) && initctl start tgt

  set -e
}

function init_db() {
  host_nodes=${host_nodes:?"host_nodes needs to be set"}

  for dbname in wakame_dcmgr wakame_dcmgr_gui; do
    yes | mysqladmin -uroot drop ${dbname} || :
    mysqladmin -uroot create ${dbname}
  done

  cd ${prefix_path}/dcmgr
  bundle exec rake db:init

  cd ${prefix_path}/frontend/dcmgr_gui
  bundle exec rake db:init

  echo ... rake oauth:create_consumer[${account_id}]
  #local oauth_keys=$(rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
  eval ${oauth_keys}

  did_have_main=0

  for node in $host_nodes; do
    [[ $node =~ ^([^:]+):([0-9.]+)$ ]] || abort "Failed to parse node 'name:ip': ${node}"
    id=${BASH_REMATCH[1]}
    ip=${BASH_REMATCH[2]}

    if [[ "${ip}" == "${ipaddr}" ]]; then
      # Install the main data.
      (node_id=${id} . $data_path/demodata.sh)
      did_have_main=1
    else
      (hva_id=${id} sta_id=${id} hva_arch=$(uname -m) ipaddr=${ip} add_host)
    fi
  done

  [[ did_have_main != 1 ]] || abort "Main host node not defined."
}

function add_host() {
  # Install remote host node demo data.
  hva_arch=${hva_arch:?"hva_arch needs to be set"}
  sta_server=${ipaddr:?"ipaddr needs to be set"}

  (. $data_path/demodata_hva.sh)
  (. $data_path/demodata_sta.sh)
}

function run_multiple() {
  host_nodes=${host_nodes:?"host_nodes needs to be set"}

  # screen
  cd ${prefix_path}

  screen_open || abort "Failed to start new screen session"
  sleep 1
  screen_it collector "cd ./dcmgr; ./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
  screen_it metadata  "cd ./dcmgr; bundle exec unicorn -p ${metadata_port} -o ${metadata_bind} ./config-metadata.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
  sleep 1
  screen_it api       "cd ./dcmgr; bundle exec unicorn -p ${api_port} -o ${api_bind} ./config-dcmgr.ru 2>&1 | tee ${tmp_path}/vdc-dcmgr.log"
  screen_it auth      "cd ./frontend/dcmgr_gui; bundle exec unicorn -p ${auth_port} -o ${auth_bind} ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"
  sleep 1
  screen_it proxy     "${abs_path}/builder/conf/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${tmp_path}/proxy.conf"
  screen_it webui     "cd ./frontend/dcmgr_gui; bundle exec unicorn -p ${webui_port} -o ${webui_bind} ./config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"
  sleep 1

  for node in $host_nodes; do
    [[ $node =~ ^([^:]+):([0-9.]+)$ ]] || abort "Failed to parse node 'name:ip': ${node}"
    id=${BASH_REMATCH[1]}
    ip=${BASH_REMATCH[2]}

    if [[ "${ip}" == "${ipaddr}" ]]; then
      screen_it nsa       "cd ./dcmgr; ./bin/nsa -i ${id} 2>&1 | tee ${tmp_path}/vdc-nsa.log"
      sleep 1
      screen_it hva-${id} "cd ./dcmgr; ./bin/hva -i ${id} 2>&1 | tee ${tmp_path}/vdc-hva.log"
      sleep 1
      screen_it sta-${id} "cd ./dcmgr; ./bin/sta -i ${id} 2>&1 | tee ${tmp_path}/vdc-sta.log"
    else
      screen_it hva-${id} "echo \"cd ${abs_path}/ && host_node_id=${id} ampq_server=${ipaddr} ./vdc-multiple.sh run_remote_hva 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh -o 'StrictHostKeyChecking no' ${ip}"
      sleep 1
      screen_it sta-${id} "echo \"cd ${abs_path}/ && host_node_id=${id} ampq_server=${ipaddr} ./vdc-multiple.sh run_remote_sta 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh -o 'StrictHostKeyChecking no' ${ip}"
      sleep 1
    fi
  done
}

function run_remote_hva() {
  host_node_id=${host_node_id:?"host_node_id needs to be set"}
  (cd ${prefix_path}/dcmgr; ./bin/hva -i ${host_node_id} -s amqp://${ampq_server}/ 2>&1 | tee ${tmp_path}/vdc-hva.log)
}

function run_remote_sta() {
  host_node_id=${host_node_id:?"host_node_id needs to be set"}
  (cd ${prefix_path}/dcmgr; ./bin/sta -i ${host_node_id} -s amqp://${ampq_server}/ 2>&1 | tee ${tmp_path}/vdc-sta.log)
}

mode=$1

case ${mode} in
  install|install::*)
    # install | install::ubuntu | install::rhel | ...
    distro=${mode##install::}; distro=${distro:-ubuntu}
    (. $data_path/install.sh)
    (. $data_path/setup.sh)
    ;;
  init)
    init_db
    ;;
  cleanup)
    cleanup
    ;;
  add_host)
    add_host
    ;;
  run_remote_hva)
    run_remote_hva
    ;;
  run_remote_sta)
    run_remote_sta
    ;;
  *)
    # interactive mode
    cleanup

    init_db
    sleep 1

    run_multiple
    screen_attach
    screen_close
    ;;
esac
