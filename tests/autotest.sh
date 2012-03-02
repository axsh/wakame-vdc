#!/usr/bin/env bash

abs_path=$(cd $(dirname $0) && pwd)
prefix_path=$(cd ${abs_path}/../ && pwd)
tmp_path=${prefix_path}/tmp
screenrc_path=${tmp_path}/screenrc
builder_path=${prefix_path}/tests/builder
mode=$1
scenario=$2

. $builder_path/functions.sh

[ -z ${mode} ] && abort "Usage: "$0" install|standalone [scenario]|multiple [scenario]|openflow [scenario]|build_cd"

[[ $UID = 0 ]] || abort "Need to run with root privilege"
trap 'echo $BASH_COMMAND "(line ${LINENO}: $BASH_SOURCE, pwd: $PWD)"' DEBUG

function run_virtual_hva {
  local tmp_path=/tmp
  local image_dir=${tmp_path}/images
  local process_id_path=${tmp_path}/pids
  local base_image_name=ubuntu-lucid-64-vhva.raw

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
            screen_it hva.${hvaname} "echo \"cd /root/wakame-vdc/dcmgr/ && ./bin/hva -i ${hvaname} -s amqp://${ipaddr}/ 2>&1 | tee ${tmp_path}/vdc-hva.log\" | ssh -o 'StrictHostKeyChecking no ' -i /tmp/vhva.pem ${h}"
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
    vhva_number=`echo ${vhva_ip} | cut -d '.' -f4`
    vhva_id=demo${vhva_number}
    process_id_path=/tmp/pids
    image_path=/tmp/images
    image_name=ubuntu-lucid-64-${vhva_id}.raw
    
    shlog "kill `cat $process_id_path/${vhva_id}`"
    shlog "rm ${process_id_path}/${vhva_id}"
    sleep 2
    shlog "tunctl -d $vhva_id"
    shlog "rm ${image_path}/${image_name}"
  done
}

set_default_variables

cleanup

excode=0
case ${mode} in
  install)
    setup_base
    ;;
  standalone)
    (
     set +e
     run_standalone
     check_ready_standalone
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  multiple)
    (
     set +e
     . builder/conf/nodes.conf
     cleanup_multiple
     run_multiple
     check_ready_multiple
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  term_vhva)
    . builder/conf/virtual_hva.conf
    terminate_virtual_hva
    ;;
  virtual_hva)
    . ${prefix_path}/tests/image_builder/build_functions.sh
    (
      set +e
      . builder/conf/virtual_hva.conf
      storage_nodes=$ipaddr
      run_virtual_hva
      
      for ip in ${host_nodes}; do
        echo "Waiting for the virtual hva at ${ip} to finish configuring itself"
        retry 25 10 "ssh -o 'StrictHostKeyChecking no ' -i /tmp/vhva.pem ${ip} \"[ -f /root/firstboot_done ]\"" || abort "failed to configure virtual hva ${ip}"
      done
      
      #cleanup_multiple
      screen_virtual_hva
      check_ready_multiple
      exec_scenario
    )
    excode=$?
    screen_close
    terminate_virtual_hva
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  openflow)
    # disable shell exit on error which caused by test cases.
    (
     set +e
     with_openflow=yes
     run_standalone
     check_ready_standalone
     exec_scenario
    )
    excode=$?
    screen_close
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
    ;;
  build_cd)
    # build image
    cd_builder_dir="${prefix_path}/tests/cd_builder"
    build_image_file="ubuntu-10.04.3-server-amd64.iso"
    build_image="/var/tmp/${build_image_file}"
    build_image_source="http://releases.ubuntu.com/lucid/${build_image_file}"
    builded_image="${cd_builder_dir}/wakame-vdc-*-amd64.iso"

    ( 
      set +e
      #check_ready_standalone

      cd "${cd_builder_dir}"

      # run build iso image.
      [[ ! -e "${build_image}" ]] && { 
        ${prefix_path}/dcmgr/script/pararell-curl.sh --url=${build_image_source} --output_path=$build_image
      }

      if [ -e "${build_image}" ]; then
        ./build_cd.sh --without-gpg-sign ${build_image}
        rm ${builded_image}
        
      else
        abort "Couldn't find ${build_image}"
      fi
      
    )
    excode=$?
    ci_post_process "`git show | awk '/^commit / { print $2}'`" $excode
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
