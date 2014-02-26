#!/usr/bin/env bash
# Developer Shell for Wakame VDC.

set -e

abs_path=$(cd $(dirname $0) && pwd)
data_path=$(cd "${0}.d" && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
VDC_ROOT=$prefix_path
tmp_path=$VDC_ROOT/tmp
screenrc_path=${tmp_path}/screenrc

# screen mode: screen, tmux, bg
screen_mode=${screen_mode:-'screen'}

host_node_id=${host_node_id:-'demo1'}
MODULES_FILE=${MODULES_FILE:-'Modulesfile'}

PATH="${VDC_ROOT}/ruby/bin:$PATH"
export PATH VDC_ROOT

. ${abs_path}/builder/functions.sh
. ${data_path}/config.env

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

function load_modules_file() {
  local modules_file_path="$prefix_path/tests/$MODULES_FILE"
  if [[ ! -f $modules_file_path ]]; then
    echo "ERROR: Unknown module file path: ${module_file_path}" >&2
    kill -TERM $$
  fi
  # print only valid lines.
  cat $modules_file_path | grep -v -e '^\s*#'
}

function run_script_modules_d() {
  local script_name="$1"
  local -a modline

  load_modules_file | while read -a modline; do
    local modname=${modline[0]}
    [[ -d "${prefix_path}/tests/vdc.sh.d/modules.d/${modname}" ]] || return 1
    local script_path="${prefix_path}/tests/vdc.sh.d/modules.d/${modname}/${script_name}"
    if [[ -x "${script_path}" ]]; then
      echo $script_path
      echo "Running $script_name of $modname"
      (
        # populate argument variables from Modulesfile
        eval "${modline[@]:1}"
        modules_home="${prefix_path}/tests/vdc.sh.d/modules.d/${modname}"
        if [[ -f "$modules_home/config.env" ]]; then
          . $modules_home/config.env
        fi
        cd $VDC_ROOT
        . $script_path
      )
    fi
  done
}

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

  run_script_modules_d "cleanup.sh"

  set -e
}

function init_db() {
  local dbname

  for dbname in wakame_dcmgr wakame_dcmgr_gui; do
    yes | mysqladmin -uroot drop ${dbname} || :
    mysqladmin -uroot create ${dbname}
  done

  cd ${prefix_path}/dcmgr
  echo "executing 'rake db:init' => dcmgr ..."
  time bundle exec rake --trace db:init

  cd ${prefix_path}/frontend/dcmgr_gui
  echo "executing 'rake db:init' => frontend/dcmgr_gui ..."
  time bundle exec rake --trace db:init

  echo ... rake oauth:create_consumer[${account_id}]
  #local oauth_keys=$(rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
  eval ${oauth_keys}

  run_script_modules_d "init_db.sh"

  # Install demo data.
  (. $data_path/demodata.sh)
  run_script_modules_d "demodata.sh"
}

function run_standalone() {
  # screen
  cd ${prefix_path}

  screen_open || abort "Failed to start new screen session"
  sleep 1
  screen_it collector "cd ./dcmgr; ./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
  screen_it nsa       "cd ./dcmgr; ./bin/nsa -i ${host_node_id} 2>&1 | tee ${tmp_path}/vdc-nsa.log"
  screen_it metadata  "cd ./dcmgr; bundle exec unicorn -p ${metadata_port} -o ${metadata_bind} ./config-metadata.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
  screen_it api       "cd ./dcmgr; bundle exec unicorn -p ${api_port} -o ${api_bind} ./config-dcmgr.ru 2>&1 | tee ${tmp_path}/vdc-dcmgr.log"
  screen_it auth      "cd ./frontend/dcmgr_gui; bundle exec unicorn -p ${auth_port} -o ${auth_bind} ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"
  screen_it proxy     "${abs_path}/builder/conf/hup2term.sh /usr/sbin/httpd -X -f ${tmp_path}/apache-proxy.conf"
  screen_it webui     "cd ./frontend/dcmgr_gui; bundle exec unicorn -p ${webui_port} -o ${webui_bind} ./config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"
  screen_it admin     "cd ./frontend/admin; bundle exec unicorn -p ${admin_port} -o ${admin_bind} ./config.ru 2>&1 | tee ${tmp_path}/vdc-admin.log"
  run_script_modules_d "screen.sh"
}

mode=$1

case ${mode} in
  install|install::*)
    # install | install::ubuntu | install::rhel | ...
    distro=${mode##install::}; [[ "${distro}" = "install" ]] && distro=ubuntu
    (. $data_path/install.sh)
    (. $data_path/setup.sh)
    ;;
  setup::openflow)
    work_dir=${work_dir:-$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )}
    (. $data_path/openflow/setup-openflow.sh)
    (. $data_path/openflow/enable-ovs.sh)
    cp $data_path/openflow/hva.conf $prefix_path/dcmgr/config/hva.conf
    ;;
  setup|setup::*)
    distro=${mode##setup::}; [[ "${distro}" = "setup" ]] && distro=ubuntu
    (. $data_path/setup.sh)
    run_script_modules_d "setup.sh"
    ;;
  init)
    init_db
    ;;
  cleanup)
    cleanup
    ;;
  start)
    run_standalone
    screen_attach
    screen_close
    ;;
  *)
    # interactive mode
    cleanup

    init_db
    sleep 1

    run_standalone
    screen_attach
    screen_close
    ;;
esac
