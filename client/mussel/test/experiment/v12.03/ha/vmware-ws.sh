
set -e

vmware_ws_host=${vmware_ws_host:?"Require to set vmware_ws_host"}
vmware_ws_user=${vmware_ws_user:?"Require to set vmware_ws_user"}
vmware_ws_password=${vmware_ws_password:?"Require to set vmware_ws_password"}
vmware_ws_vms=${vmware_ws_vms:?"Require to set vmware_ws_vms"}

#declare -A vmware_ws_vms
#vmware_ws_vms["hn-demo1"]="[ha-datacenter/standard] CentOS6.4-vdc2/CentOS6.4-vdc2.vmx"
#vmware_ws_vms["hn-demo2"]="[ha-datacenter/standard] CentOS6.4-vdc3/CentOS6.4-vdc3.vmx"
#vmware_ws_vms["hn-demo3"]="[ha-datacenter/standard] CentOS6.4-vdc4/CentOS6.4-vdc4.vmx"

# command & variable dependency check
vmrun -T ws-shared -h "${vmware_ws_host}" -u "${vmware_ws_user}" -p \
  "${vmware_ws_password}" list > /dev/null || {
  echo "Failed to find/run vmrun command." >&2
  exit 1
}

function kill_host_node_real() {
  local host_node_uuid="$1"

  vmrun -T ws-shared -h "${vmware_ws_host}" -u "${vmware_ws_user}" -p "${vmware_ws_password}" stop "${vmware_ws_vms[$host_node_uuid]}" hard
}

function check_host_node_real() {
  local host_node_uuid="$1"

  (vmrun -T ws-shared -h "${vmware_ws_host}" -u "${vmware_ws_user}" -p "${vmware_ws_password}" list | grep "${vmware_ws_vms[$host_node_uuid]}") > /dev/null
  return $?
}
