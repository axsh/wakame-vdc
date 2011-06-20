# bash functions for test script
#

function abort() {
  echo $* >&2
  exit 1
}

# retry 3 /bin/ls
function retry {
  local retry_max=$1
  shift

  local count=$retry_max
  while [[ $count -gt 0 ]]; do
    $* && break
    count=$(($count - 1))
    sleep 1
  done

  [[ $count -eq 0 ]] && {
    abort "Retry failed [$retry_max]: ${*}"
  }
  return 0
}

function screen_it {
  retry 3 screen -L -S vdc -X screen -t $1
  screen -L -S vdc -p $1 -X stuff "$2$NL"
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



