# -*-Shell-script-*-
#
# 12.03
#

. ${BASH_SOURCE[0]%/*}/base.sh

task_index() {
  # --state=(running|stopped|terminated|alive)
  xquery="service_type=std"
  if [[ -n "${state}" ]]; then
    xquery="${xquery}\&state=${state}"
  fi
  cmd_index $*
}

task_create() {
  call_api -X POST $(urlencode_data \
    $(add_param cpu_cores           string) \
    $(add_param display_name        string) \
    $(add_param hostname            string) \
    $(add_param hypervisor          string) \
    $(add_param image_id            string) \
    $(add_param instance_spec_name  string) \
    $(add_param memory_size         string) \
    $(add_param security_groups      array) \
    $(add_param service_type        string) \
    $(add_param ssh_key_id          string) \
    $(add_param user_data          strfile) \
    $(add_param vifs               strfile) \
    $(add_param host_node_id        string) \
    $(add_param ha_enabled          string) \
   ) \
   $(add_args_param volumes) \
   $(base_uri)/${namespace}s.$(suffix)
}

task_backup() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param description  string) \
    $(add_param display_name string) \
    $(add_param is_cacheable string) \
    $(add_param is_public    string) \
    $(add_param all    string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/backup.$(suffix)
}

task_show_volumes() {
  local namespace=$1 cmd=$2 uuid=$3
  call_api -X GET $(base_uri)/${namespace}s/${uuid}/volumes.$(suffix)
}

task_backup_volume() {
  local namespace=$1 cmd=$2 uuid=$3 volume_uuid=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${volume_uuid}" ]] || { echo "[ERROR] 'volume_uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param description  string) \
    $(add_param display_name string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/volumes/${volume_uuid}/backup.$(suffix)
}

task_reboot() {
  cmd_put $*
}

_task_stop() {
  cmd_put $*
}

_task_start() {
  cmd_put $*
}

task_poweroff() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param force string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_poweron() {
  cmd_put $*
}

task_move() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param host_node_id string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}/${cmd}.$(suffix)
}

task_update() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X PUT $(urlencode_data \
    $(add_param display_name        string) \
    $(add_param ssh_key_id          string) \
   ) \
   $(base_uri)/${namespace}s/${uuid}.$(suffix)
}

task_show_password() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X GET $(base_uri)/${namespace}s/${uuid}/password.$(suffix)
}

task_decrypt_password() {
  local namespace=$1 cmd=$2 uuid=$3 ssh_key_pair_path=$4
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -f "${ssh_key_pair_path}" ]] || { echo "[ERROR] 'ssh_key_file' is incorrect (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  instance_password="$(task_show_password "$namespace" "$cmd" $uuid)" \
      || { echo "[ERROR] encrypted password not available (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  # ---
  # :id: i-czulsyoj
  # :encrypted_password: |
  #  IAAMQn+4axLf/EO+dzQWhzDOBY/dkOCvDegiL8eS1VTs9MrwgA05vnCQ//EO
  #  RaZPfWQLV4qhIjr1h4RUNQZ41Hs22lOztb2qpACuQzlfXpTKDp3YhZdOw/V8
  #  hencQ02g8uziV5+Wpy1DLikkATMrRLurp2zsg7XQp/0mO9e16YzkzO9Xor3R
  #  C+daGS/YeB8BZqQbwZgzWLnrgRm7q6zzKJoGxl67+RYHki/19n1gFQXNVyOi
  #  /gZo1sdAPF/N2a18naOM4lpbjRr4R2u82mkgCMFYzRJew9yvOTGkFhwZamkX
  #  9j+wU5Cvo0fDDpS4pXlRTvbmu9ESTmg0tSfFyuCgkA==

  # assume :encrypted_password: is the last field and
  # the CR immediately follows the | character
  instance_password="${instance_password#*:encrypted_password: |?}"
  instance_password="${instance_password// /}" # remove whitespace for base64

  plain_password="$(echo "${instance_password}" | base64 --decode \
         | openssl rsautl -decrypt -inkey "${ssh_key_pair_path}" -oaep)" \
      || { echo "[ERROR] error decrypting password (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  echo "$plain_password"
}

task_delete_password() {
  local namespace=$1 cmd=$2 uuid=$3
  [[ -n "${namespace}" ]] || { echo "[ERROR] 'namespace' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${cmd}"       ]] || { echo "[ERROR] 'cmd' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${uuid}"      ]] || { echo "[ERROR] 'uuid' is empty (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  call_api -X DELETE $(base_uri)/${namespace}s/${uuid}/password.$(suffix)
}
