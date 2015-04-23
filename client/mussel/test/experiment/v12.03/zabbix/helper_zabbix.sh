#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## functions

function load_zabbixrc() {
  ZABBIX_RC=${ZABBIX_RC:-${HOME}/.zabbixrc}
  if [[ -f "${ZABBIX_RC}" ]]; then
    . ${ZABBIX_RC}
  fi
}

function setup_zabbix_vars() {
  ZABBIXSH=${ZABBIXSH:-/home/axsh/work/zabbix-bash/zabbix.sh}
  JSONSH=${JSONSH:-/usr/local/bin/json.sh}
  api_user=${api_user:-zabbix}
  api_password=${api_password:-zabbix}
}

function zabbix_sh() {
  echo ${ZABBIXSH}
}

function json_sh() {
  echo ${JSONSH}
}

function zabbix_document_pair?() {
  local namespace=$1 cmd=$2 key=$3 val=$4
  local params=$(render_${namespace}_search_condition)
  echo $params
  [[ "$(params=${params} $(zabbix_sh) ${namespace} ${cmd} --auth=${auth} | $(json_sh) | grep ${key} | awk '{print $3}')" == "${val}" ]]
}

function render_host_search_condition() {
  cat <<-EOS
	"output": "extend",
	"filter": {
		"host": ["${instance_uuid}"]
		}
	EOS
}

function render_item_search_condition() {
  cat <<-EOS
	"output": "extend",
	"host": "${instance_uuid}",
	"filter": {
		"key_": ["${item_key}"]
		}
	EOS
}

function zabbix_api_authenticate() {
  $(zabbix_sh) user login --user ${api_user} --password ${api_password} | $(json_sh) | grep result | awk '{print $3}'
}


### instance

### environment-specific configuration
[[ -f ${BASH_SOURCE[0]%/*}/zabbixrc ]] && { . ${BASH_SOURCE[0]%/*}/zabbixrc; } || :
load_zabbixrc

### shunit2 setup
setup_zabbix_vars
