#
# bash functions for Wakame-vdc setup
#

# Todo: 
# - support multi_node
#  Idea note: For multinode, just send "sh" and invoke sh function
#    e.g. ssh $host "`cat ...`;run_func()"
shopt -s expand_aliases

#
# Identify linux distribution and fix Gem.bin path
#
function set_default_variables() {
  distrib_path="${script_path}/distrib"

  # Gentoo does not have lsb_release default
  if [ ! -f /etc/lsb-release ]; then
    echo "Wakame-vdc requires lsb-release."
    abort "Wakame-vdc does not support your distribution."
  fi
  . /etc/lsb-release

  DISTRIB_ID=${DISTRIB_ID:-`lsb_release -is`}
  DISTRIB_RELEASE=${DISTRIB_RELEASE:-`lsb_release -rs`}

  [ ! -f ${distrib_path}/${DISTRIB_ID}-${DISTRIB_RELEASE}.sh ] && \
    	abort "Cannot detect your using distribution."

  # Work around if this runs under the bundler container.
  [ -n "$BUNDLE_BIN_PATH" ] && {
    export RUBYOPT="$RUBYOPT -rubygems"
    alias bundle="$BUNDLE_BIN_PATH"
  }
  # Add bin path to $GEM_HOME/bin.
  which gem >/dev/null 2>&1 && {
    export PATH="$(ruby -rubygems -e 'puts Gem.bindir'):$PATH"
  } || :
}

#
# Install function for wakame-vdc
#
function setup_base {
  echo "Install base system..."
  [ -d $tmp_path ] || mkdir $tmp_path


  # Do platform dependent install (package or so...)
  if [ -z "${without_distrib_pkg}" ]; then
    . ${distrib_path}/${DISTRIB_ID}-${DISTRIB_RELEASE}.sh
    do_install
  fi

  # Install (platform independent)
  # Update gem and then install bundler
  echo "Install ruby packages..."
  gem install bundler

  function bundle_update() {
    local dir=$1

    [ -d $dir ] || exit 1
    # run in subshell to keep cwd.
    (
    cd $dir

    if [ -d .vendor/bundle ] ; then 
      echo "Clear $1 cache..."
      rm -rf .vendor/bundle
      echo "Clear $1 cache done."
    fi
    echo "Install ruby libs for $1..."
    # This generates .bundle/config.
    shlog bundle install --path=.vendor/bundle
    echo "Install ruby libs for $1 done."
    )
  }

  pushd ${wakame_root}
  # Update bundle package
  bundle_update ${wakame_root}/dcmgr/
  bundle_update ${wakame_root}/frontend/dcmgr_gui/
  echo "Install ruby packages done."

  # Prepare configuration files
  echo "Copying config scripts..."
  # dcmgr
  cd ${wakame_root}/dcmgr/config/
  cp -f dcmgr.conf.example dcmgr.conf
  cp -f snapshot_repository.yml.example snapshot_repository.yml
  cp -f hva.conf.example hva.conf
  cp -f nsa.conf.example nsa.conf
  cp -f sta.conf.example sta.conf
  
  # dcmgr:hva
  [ -d ${vmdir_path} ] || mkdir $vmdir_path
  perl -pi -e "s,^config.vm_data_dir = .*,config.vm_data_dir = \"${vmdir_path}\"," hva.conf
  
  # frontend
  cd ${wakame_root}/frontend/dcmgr_gui/config/
  cp -f dcmgr_gui.yml.example dcmgr_gui.yml
  echo "Copying config scripts done" 

  # Initialize database
  echo "Initialize database ..."
  init_db
  echo "Initialize database done."
}

# Cleanup current process/terminal for Wakame-vdc
# *************************************************
# Todo:
# How to manage with ipfilter or so....
# *************************************************
function cleanup {
  force=0

  if [ "$1" = "force" ]; then
    force=1
  fi

  # Clear screen
  echo "Clean screen"
  which screen >/dev/null && {
    screen -ls vdc | egrep -q vdc && {
      screen -S vdc -X quit
    }
  } || :
  # Todo: should we do same things on tmux?

  # Stop dnsmasq
  echo "Stop dnsmasq..."
  if [ $force -eq 1 ]; then 
    ps -ef | egrep '[d]nsmasq' -q && {
      killall dnsmasq
    }

    # Stop iSCSI
    echo "Stop iSCSI target..."
    ps -ef | egrep '[t]gtd' -q && {
      /sbin/iscsiadm -m node -u
      /usr/sbin/tgt-admin --dump | grep ^\<target | awk '{print $2}' | sed 's,>$,,' | while read iqn; do echo ... ${iqn}; /usr/sbin/tgt-admin --delete ${iqn}; done
      initctl restart tgt || /etc/init.d/tgtd restart
    }
  
    # Stop running kvm/lxc
    case ${hypervisor} in
    kvm)
      echo "Stop kvm..."
      ps -ef | egrep 'bin/[k]vm' -q && {
        killall kvm
      }
     ;;
    lxc)
      echo "Stop lxc..."
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
  
    # Clear Netfilter (iptables/ebtables)
    echo "Clean ebtables..."
    which ebtables >/dev/null && ebtables --init-table || :
    echo "Clean iptables..."
    for table in nat filter; do
      for xcmd in F Z X; do
        which iptables >/dev/null && iptables -t ${table} -${xcmd} || :
      done
    done

  fi

  # Cleanup wakame-vdc process
  for component in collector nsa hva sta; do
    echo "Stop ${component}..."
    pid=$(ps awwx | egrep "[b]in/${component}" | awk '{print $1}')
    [ -z "${pid}" ] || kill -9 ${pid}
  done

  # Cleanup rackup
  for port in ${ports}; do
    echo "Stop rackup port:${port}..."
    pid=$(ps awwx | egrep "[r]ackup -p ${port}" | awk '{print $1}')
    [ -z "${pid}" ] || kill -9 ${pid}
  done

  [ -d ${wakame_root}/frontend/dcmgr_gui/log/ ] && {
    [ -f ${wakame_root}/frontend/dcmgr_gui/log/proxy_access.log ] || : && \
      echo ": > ${wakame_root}/frontend/dcmgr_gui/log/proxy_access.log" | /bin/sh
  } || :

  # Remove previous logfile
  for i in ${tmp_path}/screenlog.* ${tmp_path}/*.log; do rm -f ${i}; done

  # Remove previous volume
  [ -d ${tmp_path}/xpool/${account_id} ] && {
    for i in ${tmp_path}/xpool/${account_id}/*; do rm -f ${i}; done
  }

  # Remove previous snapshot
  [ -d ${tmp_path}/snap/${account_id} ] && {
    for i in ${tmp_path}/snap/${account_id}/*; do rm -f ${i}; done
  }
  echo "Clenup done."
}


# Initialize MySQL DB
function init_db() {
  dbnames="wakame_dcmgr wakame_dcmgr_gui"
  rake="bundle exec rake"

  # Drop wakame-vdc DB
  echo "Drop DBs ..."
  for dbname in ${dbnames}; do
    yes | mysqladmin -uroot drop ${dbname}
    mysqladmin -uroot create ${dbname}
  done
  echo "grant all on ${webui_dbname}.* to ${webui_dbname}@localhost identified by '${webui_dbpass:-passwd}'" | mysql -uroot ${webui_dbname} 

  echo "Create DBs ..."
  # Create dcmgr schema
  cd ${wakame_root}/dcmgr
  ${rake} db:init

  # Create dcmgr_gui schema
  cd ${wakame_root}/frontend/dcmgr_gui
  ${rake} db:init db:sample_data admin:generate_i18n oauth:create_table

  # Generate oauth config
  echo "Config oauth..."
  echo ... rake oauth:create_consumer[${account_id}]
  local oauth_keys=$(${rake} oauth:create_consumer[${account_id}] | egrep -v '^\(in')
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

}

#
# Run wakame-vdc
#
function run_standalone() {
  # forece reset and restart rabbitmq

  echo "Restarting rabbitmq..."
  if [ "${DISTRIB_ID}" == "Gentoo" ]; then
  	/etc/init.d/rabbitmq status && /etc/init.d/rabbitmq stop
  else 
  	/etc/init.d/rabbitmq-server status && /etc/init.d/rabbitmq-server stop
  fi

  [ -f /var/lib/rabbitmq/mnesia/ ] && rm -rf /var/lib/rabbitmq/mnesia/

  if [ "${DISTRIB_ID}" == "Gentoo" ]; then
        /etc/init.d/rabbitmq start
  else 
  	/etc/init.d/rabbitmq-server start
  fi

  echo "Restarting iSCSI..."
  [[ -x /etc/init.d/tgt ]] && { initctl restart tgt; }

  sleep 1

  # Now, run wakame-vdc!
  cd ${wakame_root}
  # Invoke script(service) with/without screen
  function run_service {
    if [ -z "${without_screen}" ]; then
      screen_it "$1" "$2 && $3"
    else
      $2 && run2bg "$3"
    fi
  }

  echo "Run wakame-vdc..."
  if [ -z "${without_screen}" ]; then
    screen_open || abort "Failed to start new screen session"
  fi

  run_service "collector" "cd ${wakame_root}/dcmgr/" "./bin/collector 2>&1 | tee ${tmp_path}/vdc-collector.log"
  run_service "nsa" "cd ${wakame_root}/dcmgr/" "./bin/nsa -i demo1 2>&1 | tee ${tmp_path}/vdc-nsa.log"

  for i in $(seq 1 ${hva_num}); do
    run_service "hva${i}" "cd ${wakame_root}/dcmgr/" "./bin/hva -i demo${i} 2>&1 | tee ${tmp_path}/vdc-hva${i}.log"
  done

  run_service "metadata"  "cd ${wakame_root}/dcmgr/web/metadata" "bundle exec rackup -p ${metadata_port} -o ${metadata_bind:-127.0.0.1} ./config.ru 2>&1 | tee ${tmp_path}/vdc-metadata.log"
  run_service "api" "cd ${wakame_root}/dcmgr/web/api" "bundle exec rackup -p ${api_port} -o ${api_bind:-127.0.0.1} ./config.ru 2>&1 | tee ${tmp_path}/vdc-api.log"
  run_service "auth" "cd ${wakame_root}/frontend/dcmgr_gui" "bundle exec rackup -p ${auth_port} -o ${auth_bind:-127.0.0.1} ./app/api/config.ru 2>&1 | tee ${tmp_path}/vdc-auth.log"

  #XXX: need to revisit for proxy.conf path.
  run_service "proxy" "cd ." "${script_path}/hup2term.sh /usr/sbin/nginx -g \'daemon off\;\' -c ${wakame_root}/tests/builder/conf/proxy.conf"
  run_service "webui" "cd ${wakame_root}/frontend/dcmgr_gui/config" "bundle exec rackup -p ${webui_port} -o ${webui_bind:-0.0.0.0} ../config.ru 2>&1 | tee ${tmp_path}/vdc-webui.log"

  [ "${sta_server}" = "${ipaddr}" ] && {
    for i in $(seq 1 ${sta_num}); do
      run_service "sta${i}" "cd ${wakame_root}/dcmgr/" "./bin/sta -i demo${i} 2>&1 | tee ${tmp_path}/vdc-sta${i}.log"
    done
  }

  [ "${with_openflow}" != "yes" ] || \
    run_service "ofc" "cd ${wakame_root}/dcmgr/" "./bin/ofc -i demo1"

  [ -n "${without_screen}" ] && {
    #wait_jobs
    echo "Kill pids in ${tmp_path}/vdc-pid.log..."
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
