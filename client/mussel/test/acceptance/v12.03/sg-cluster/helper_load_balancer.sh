#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare load_balancer_ipaddr=

declare instance_uuids_path=$(generate_cache_file_path instance_uuids)
declare instance_vifs_path=$(generate_cache_file_path instance_vifs)

declare common_name=example.com

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:${DCMGR_CLIENT_ADDR}/32
	tcp:22,22,ip4:${DCMGR_CLIENT_ADDR}/32
	tcp:80,80,ip4:0.0.0.0/0
	EOS
}

function oneTimeSetUp() {
  # ssl-cert
  setup_self_signed_key ${common_name}

  # create
  for i in $(eval echo "{1..${target_instance_num:-1}}"); do
    instance_uuid= security_group_uuid= ssh_key_pair_uuid=
    create_instance
    instance_vifs="$(cached_instance_param ${instance_uuid}  | hash_value vif_id)"

    echo ${instance_uuid} >> ${instance_uuids_path}
    echo ${instance_vifs} >> ${instance_vifs_path}
  done

  private_key=${load_balancer_private_key} public_key=${load_balancer_public_key} create_load_balancer

  # wait
  for instance_uuid in $(cat ${instance_uuids_path}); do
    instance_ipaddr="$(cached_instance_param ${instance_uuid} | hash_value address)"
    wait_for_network_to_be_ready ${instance_ipaddr}
    wait_for_port_to_be_ready    ${instance_ipaddr} tcp ${instance_port}
  done
  load_balancer_ipaddr=$(run_cmd load_balancer show ${load_balancer_uuid} | hash_value address | head -1)
  wait_for_network_to_be_ready ${load_balancer_ipaddr}
  wait_for_port_to_be_ready    ${load_balancer_ipaddr} tcp ${port}

  # register instances to load_balancer
  vifs="$(cat ${instance_vifs_path})" run_cmd load_balancer register ${load_balancer_uuid}
  retry_until "curl -fsSkL http://${load_balancer_ipaddr}/"
}

function oneTimeTearDown() {
  for instance_uuid in $(cat ${instance_uuids_path}); do
    ssh_key_pair_uuid="$(cached_instance_param ${instance_uuid}   | egrep ' ssh-' | awk '{print $2}')"
    security_group_uuid="$(cached_instance_param ${instance_uuid} | egrep ' sg-'  | awk '{print $2}')"
    destroy_instance
  done
  destroy_load_balancer

  rm -f ${instance_uuids_path}
  rm -f ${instance_vifs_path}

  # ssl-cert
  teardown_self_signed_key ${common_name}
}
