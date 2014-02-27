# bash functions for test script
#

alias rake="bundle exec rake"
shopt -s expand_aliases

function set_default_variables() {
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
        key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
        value=${arg##--*=}
        eval ${key}=${value}
        opts="${opts} ${key}"
        ;;
    esac
  done
  unset opts

  # work around if this runs under the bundler container.
  [[ -n "$BUNDLE_BIN_PATH" ]] && {
    export RUBYOPT="$RUBYOPT -rubygems"
    alias bundle="$BUNDLE_BIN_PATH"
  }
  # add bin path to $GEM_HOME/bin.
  which gem >/dev/null 2>&1 && {
    export PATH="$(ruby -rubygems -e 'puts Gem.bindir'):$PATH"
  } || :

  #alias rake="bundle exec rake"
  #shopt -s expand_aliases
}

function exec_scenario() {
  cd $prefix_path/tests/cucumber
  [ -z "${without_bundle_install}" ] && bundle install --path=.vendor/bundle
  if [ -z "${scenario}" ]; then
    # Perform all tests if no scenario is specified
    bundle exec cucumber
  elif [ -f features/${scenario}/autotest.sh ]; then
    # Execute autotest.sh if there is one
    prefix_path=${prefix_path} features/${scenario}/autotest.sh
  else
    # Execute all feature files in the scenario directory if there is no autotest.sh
    bundle exec cucumber -r features features/${scenario}
  fi
}

function abort() {
  echo $* >&2
  exit 1
}

# Run multiple sequence of comand lines
#run 'ls /'
#run 'echo && echo && ls /'
#
#run <<_END
#ls / && echo 1
#ls / || echo 2
#ls / && echo 3
#_END
function run {
  local ret=0
  if [[ -t 0 ]]; then
    eval "$*"
    ret=$?
  else
    read -u 0 -d '' i
    eval "$i"
    ret="$?"
  fi

  return $ret
}

# retry 3 /bin/ls
# echo "ls / " | retry 3
function retry {
  local sleep_time=1
  local retry_max="$1"
  shift

  if [[ $1 =~ ^[0-9]+$  ]]; then
    sleep_time=$1
    shift
  fi

  typeset cmdlst="" i
  if [[ -t 0 ]]; then
    cmdlst="$*"
  else
    read -u 0 -d '' i
    cmdlst="$i"
  fi

  local count="$retry_max"
  local lastret=0
  while [[ $count -gt 0 ]]; do
    eval "$cmdlst"
    lastret="$?"
    [[ $lastret -eq 0 ]] && break
    count=$(($count - 1))
    echo "retry hold [$(($retry_max - $count))/${retry_max}] sleep:[${sleep_time}]...."
    /bin/sleep $sleep_time
  done

  [[ ( $count -eq 0 ) && ( $lastret -ne 0 ) ]] && {
    echo "Retry failed [$retry_max]: ${*}" >&2
    return 1
  }
  return 0
}

NL=`echo -ne '\015'`

function screen_it {
  local title=$1
  local cmd=$2

  # read cmd lines from stdin
  [[ -z "$cmd"  ]] && {
    cmd="$cmd `read`"
  }

  case $screen_mode in
      'tmux')
          (tmux -S "${tmp_path}/vdc-tmux.s" list-windows -t vdc | grep ${title} >/dev/null) || {
              tmux -S "${tmp_path}/vdc-tmux.s" new-window -n "$title"
              # pipe-pane can not be called from command line in tmux version earlier than the revision below.
              # http://sourceforge.net/mailarchive/message.php?msg_id=27900401
              #tmux -v -S "${tmp_path}/vdc-tmux.s" pipe-pane -t "vdc:${title}.0" "'/bin/cat > \"${tmp_path}/screenlog.${title}\"'"
          }
          tmux -S "${tmp_path}/vdc-tmux.s" send-keys -t "vdc:${title}" "${cmd}" \; send-keys "Enter"
          ;;
      'screen')
          retry 3 screen -L -r vdc -x -X screen -t $title
          screen -L -r vdc -x -p $title -X stuff "${cmd}$NL"
          ;;
      'bg')
          run2bg "($cmd) > ${tmp_path}/vdc-${title}.log"
          ;;
      *)
          :
          ;;
  esac
}

function screen_it_remote {
  local title=$1
  local ssh_dest=$2
  local cmd=$3

  # read cmd lines from stdin
  [[ -z "$cmd"  ]] && {
    cmd="$cmd `read`"
  }

  case $screen_mode in
      'tmux')
          (tmux -S "${tmp_path}/vdc-tmux.s" list-windows -t vdc | grep ${title} >/dev/null) || {
              tmux -S "${tmp_path}/vdc-tmux.s" new-window -n "$title"
              # pipe-pane can not be called from command line in tmux version earlier than the revision below.
              # http://sourceforge.net/mailarchive/message.php?msg_id=27900401
              #tmux -v -S "${tmp_path}/vdc-tmux.s" pipe-pane -t "vdc:${title}.0" "'/bin/cat > \"${tmp_path}/screenlog.${title}\"'"
          }
          tmux -S "${tmp_path}/vdc-tmux.s" send-keys -t "vdc:${title}" "ssh ${ssh_dest}" \; send-keys "Enter"
          if [[ $cmd = '-' ]]; then
            while read cmdln; do
              tmux -S "${tmp_path}/vdc-tmux.s" send-keys -t "vdc:${title}" "${cmdln}" \; send-keys "Enter"
            done
          else
            tmux -S "${tmp_path}/vdc-tmux.s" send-keys -t "vdc:${title}" "${cmd}" \; send-keys "Enter"
          fi
          ;;
      'screen')
          retry 3 screen -L -r vdc -x -X screen -t $title
          screen -L -r vdc -x -p $title -X stuff "ssh ${ssh_dest} $NL"
          screen -L -r vdc -x -p $title -X stuff "${cmd}$NL"
          ;;
  esac
}

function screen_open {
    typeset ret=0

    case $screen_mode in
        'tmux')
            echo "Creating tmux windows..."
            tmux -S "${tmp_path}/vdc-tmux.s" new-session -d -s vdc
            ret=$?
            ;;
        'screen')
            echo "Creating screen windows..."
            # screen configuration file
            /bin/cat <<EOS > "${tmp_path}/screenrc"
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<"
defscrollback 10000
logfile ${tmp_path}/screenlog.%t
logfile flush 1
EOS
            screen -L -d -m -S vdc -t vdc -c "${tmp_path}/screenrc"
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

function screen_close {
    typeset ret=0

    case $screen_mode in
        'tmux')
            tmux -S "${tmp_path}/vdc-tmux.s" has-session -t vdc && \
                tmux -S "${tmp_path}/vdc-tmux.s" kill-session -t vdc
            ret=$?
            ;;
        'screen')
            screen -ls | grep vdc >/dev/null && \
                screen -S vdc -X quit
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

function screen_attach {
    typeset ret=0

    case $screen_mode in
        'tmux')
            tmux -S "${tmp_path}/vdc-tmux.s" attach-session -t vdc
            ret=$?
            ;;
        'screen')
            screen -x -S vdc
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

function setup_base {
  [ -d $tmp_path ] || mkdir $tmp_path

  run_builder "00_install-pkg.sh"
  (
      work_dir=$prefix_path
      run_builder "99_setup-developer.sh"
  )
}

function cleanup {
  which screen >/dev/null && {
    screen -ls vdc | egrep -q vdc && {
      screen -S vdc -X quit
    }
  } || :

  ps -ef | egrep 'bin/[d]nsmasq' -q && {
    killall dnsmasq
  }

  ps -ef | egrep '[t]gtd' -q && {
    /sbin/iscsiadm -m node -u
    /usr/sbin/tgt-admin --dump | grep ^\<target | awk '{print $2}' | sed 's,>$,,' | while read iqn; do echo ... ${iqn}; /usr/sbin/tgt-admin --delete ${iqn}; done
    initctl restart tgt || /etc/init.d/tgtd restart
  }

  case ${hypervisor} in
  kvm)
    ps -ef | egrep 'bin/[k]vm' -q && {
      killall kvm
    }
   ;;
  lxc)
    which lxc-ls >/dev/null && {
      for container_name in $(lxc-ls); do
        echo ... ${container_name}
        lxc-destroy -n ${container_name} || lxc-kill -n ${container_name}
      done
    }
    unset container_name

    mount | egrep ${vmdir_path} | awk '{print $3}' | while read line ;do
      echo ... ${line}
      umount ${line}
    done
    unset line
   ;;
  esac

  for component in collector nsa hva sta; do
    pid=$(ps awwx | egrep "[b]in/${component}" | awk '{print $1}')
    [ -z "${pid}" ] || kill -9 ${pid}
  done

  for port in ${ports}; do
    pid=$(ps awwx | egrep "[r]ackup -p ${port}" | awk '{print $1}')
    [ -z "${pid}" ] || kill -9 ${pid}
  done

  # netfilter
  which ebtables >/dev/null && ebtables --init-table || :
  for table in nat filter; do
    for xcmd in F Z X; do
      which iptables >/dev/null && iptables -t ${table} -${xcmd} || :
    done
  done

  [ -d ${prefix_path}/frontend/dcmgr_gui/log/ ] && {
    [ -f ${prefix_path}/frontend/dcmgr_gui/log/proxy_access.log ] || : && \
      echo ": > ${prefix_path}/frontend/dcmgr_gui/log/proxy_access.log" | /bin/sh
  } || :

  # logfile
  for i in ${tmp_path}/screenlog.* ${tmp_path}/*.log; do rm -f ${i}; done

  # volume
  [ -d ${tmp_path}/xpool/${account_id} ] && {
    for i in ${tmp_path}/xpool/${account_id}/*; do rm -f ${i}; done
  }

  # snapshot
  [ -d ${tmp_path}/snap/${account_id} ] && {
    for i in ${tmp_path}/snap/${account_id}/*; do rm -f ${i}; done
  }
}

function cleanup_multiple {
    for h in ${host_nodes};do
        [ "${h}" = "${ipaddr}" ] || {
            cat <<EOF | ssh ${h}
# delete instance
case ${hypervisor} in
kvm)
ps -ef | egrep '[k]vm' -q && {
killall kvm
}
;;
lxc)
which lxc-ls >/dev/null && {
for container_name in \$(lxc-ls); do
echo ... \${container_name}
lxc-destroy -n \${container_name} || lxc-kill -n \${container_name}
done
}
unset container_name

mount | egrep ${vmdir_path} | awk '{print \$3}' | while read line; do
echo ... \${line}
umount \${line}
done
unset line
;;
esac

# stop hva
pid=\$(ps awwx | egrep "[b]in/hva" | awk '{print \$1}')
[ -z "\${pid}" ] || kill -9 \${pid}

# stop netfilter
which ebtables >/dev/null && ebtables --init-table || :
for table in nat filter; do
for xcmd in F Z X; do
which iptables >/dev/null && iptables -t \${table} -\${xcmd} || :
done
done

# delete logfile
for i in ${tmp_path}/screenlog.* ${tmp_path}/*.log; do rm -f \${i}; done
EOF
        }
    done

    for s in ${storage_nodes}; do
        [ "${s}" = "${ipaddr}" ] || {
            cat <<EOF | ssh ${s}
# restart tgt
ps -ef | egrep '[t]gtd' -q && {
initctl restart tgt
}

# stop sta
pid=\$(ps awwx | egrep "[b]in/sta" | awk '{print \$1}')
[ -z "\${pid}" ] || kill -9 \${pid}

# delete logfile
for i in ${tmp_path}/screenlog.* ${tmp_path}/*.log; do rm -f \${i}; done

# delete volume
[ -d ${tmp_path}/xpool/${account_id} ] && {
for i in ${tmp_path}/xpool/${account_id}/*; do rm -f \${i}; done
}

# delete snapshot
[ -d ${tmp_path}/snap/${account_id} ] && {
for i in ${tmp_path}/snap/${account_id}/*; do rm -f \${i}; done
}
EOF
        }
    done
}

# kick the builder script.
#
# use following form to set configurable variables for xxx.sh:
# ( val1=1; run_builder "xxx.sh"; )
function run_builder {
  local builder_script=$1

  i="$DISTRIB_ID/$DISTRIB_RELEASE/$builder_script"
  [ -f "$builder_path/$i" ] || abort "ERROR: Unknown builder script: $builder_script"
  # run script in subshell to inherit variables.
  (
    [[ -f $(dirname $builder_path/$i)/common.sh ]] && {
      . $(dirname $builder_path/$i)/common.sh
    }
    . $builder_path/$i
  ) || abort "Failed to run $builder_script"
  return 0
}

function shlog {
  echo $* "(cwd: `pwd`)"
  eval $*
}

# for without_screen
pids=
trap 'kill -9 ${pids};' 2

function run2bg() {
  #eval "$* &"
  shlog "$* &"

  pid=$!
  echo "[pid:${pid}]# '$*'"
  pids="${pids} ${pid}"
}

function init_db() {
  dbnames="wakame_dcmgr wakame_dcmgr_gui"
  for dbname in ${dbnames}; do
    yes | mysqladmin -uroot drop   ${dbname}
    mysqladmin -uroot create ${dbname}
  done

  cd ${prefix_path}/dcmgr
  rake db:init

  cd ${prefix_path}/frontend/dcmgr_gui
  rake db:init db:sample_data oauth:create_table

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
    #wait_jobs
    echo "${pids}" > ${tmp_path}/vdc-pid.log
    shlog ps -p ${pids}
  }

}

function check_ready_standalone {
  retry 10 <<'EOF' || abort "Can't see dcmgr"
echo > "/dev/tcp/${api_bind}/${api_port}"
EOF
  retry 10 <<'EOF' || abort "Can't see nginx"
echo > "/dev/tcp/localhost/8080"
EOF

  nodes=4

  # Wait for until all agent nodes become online.
  retry 10 <<'EOF' || abort "Offline nodes still exist."
sleep 5
[ ${nodes} -eq "`echo "select state from node_states where state='online'" | mysql -uroot wakame_dcmgr | wc -l`" ]
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
    echo "[ -d ${prefix_path} ] || mkdir -p ${prefix_path}"
    echo "rsync -avz -e ssh ${ipaddr}:${prefix_path}/ ${prefix_path}"
	  cat <<EOF | ssh ${h}
[ -d ${prefix_path} ] || mkdir -p ${prefix_path}
rsync -avz -e ssh ${ipaddr}:${prefix_path}/ ${prefix_path}
EOF
      }
  done

  for s in ${storage_nodes}; do
      [ "${s}" = "${ipaddr}" ] || {
      cat <<EOF | ${s}
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
            screen_it hva.${hvaname} "echo \"cd ${prefix_path}/dcmgr/ && ./bin/hva -i ${hvaname} -s amqp://${ipaddr}/ 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh ssh -o 'StrictHostKeyChecking no' ${h}"
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

function run_virtual_hva {
  tmp_path=/tmp/vhva
  image_dir=${tmp_path}/images
  process_id_path=${tmp_path}/pids
  base_image_name=ubuntu-lucid-64-vhva.raw

  if [ ! -d $image_dir ]; then
    mkdir -p $image_dir
  fi

  # Generate the base hva image if it doesn't exist
  if [ ! -f ${image_dir}/${base_image_name} ]; then
    #TODO: try downloading the base image first
    rootsize=10240
    swapsize=512

    run_vmbuilder_hva ${image_dir}/${base_image_name} "amd64"
  fi

  #TODO:improve the mac generation
  host_macs=54
  for vhva_ip in ${host_nodes}; do
    vhva_number=`echo ${vhva_ip} | cut -d '.' -f4`
    vhva_id=demo${vhva_number}
    image_name=ubuntu-lucid-64-${vhva_id}.raw
    vhva_mac="52:54:00:51:90:${host_macs}"

    cd $image_dir
    shlog "cp --sparse=auto $base_image_name $image_name"

    #loop_mount_image $image_name "kvm_base_setup"
    loop_mount_image $image_name setup_hva $vhva_id $vhva_ip $vhva_netmask $vhva_gateway $vhva_dns

    # Start the hva in bridged networking mode
    if [ ! -d $process_id_path ]; then
      mkdir -p $process_id_path
    fi
    shlog "tunctl -b -u root -t $vhva_id"
    shlog "kvm -smp 1 -cpu host -enable-nesting -enable-kvm -drive file=${image_dir}/${image_name} -name hva.${vhva_id} -m $vhva_memory_size -net nic,macaddr=${vhva_mac} -net tap,ifname=$vhva_id -enable-kvm -vnc :${vhva_number} &"
    shlog "echo $! > $process_id_path/$vhva_id"

    host_macs=$(($host_macs+1))
  done
}

function screen_virtual_hva {
  # forece reset and restart rabbitmq
  /etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  [ -f /var/lib/rabbitmq/mnesia/ ] && rm -rf /var/lib/rabbitmq/mnesia/
  /etc/init.d/rabbitmq-server start

  [[ -x /etc/init.d/tgt ]] && { initctl restart tgt; }

  demo_resource="92_generate-demo-resource.sh"
  init_db
  sleep 1

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
            echo "starting ${hvaname}"
            screen_it hva.${hvaname} "echo \"cd /root/wakame-vdc/dcmgr/ && ./bin/hva -i ${hvaname} -s amqp://${ipaddr}/ 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh -o 'StrictHostKeyChecking no ' -i ${tmp_path}/vhva.pem ${h}"
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

function terminate_virtual_hva {
  for vhva_ip in $host_nodes; do
    local vhva_number=`echo ${vhva_ip} | cut -d '.' -f4`
    local vhva_id=demo${vhva_number}
    local image_name=ubuntu-lucid-64-${vhva_id}.raw

    shlog "kill `cat $process_id_path/${vhva_id}`"
    shlog "rm ${process_id_path}/${vhva_id}"
    sleep 2
    shlog "tunctl -d $vhva_id"
    shlog "rm ${image_dir}/${image_name}"
  done
}
