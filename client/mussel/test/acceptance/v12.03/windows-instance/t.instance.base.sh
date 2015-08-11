#!/bin/bash
#
# requires:
#  bash
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

rdp_user="${rdp_user:-"Administrator"}"

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:3389,3389,ip4:0.0.0.0/0
	EOS
}

### step

function test_get_instance_ipaddr() {
  instance_ipaddr="$(run_cmd instance show ${instance_uuid} | hash_value address)"
  assertEquals 0 $?
}

function test_wait_for_network_to_be_ready() {
  wait_for_network_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

function test_wait_for_rdpd_to_be_ready() {
  wait_for_rdpd_to_be_ready ${instance_ipaddr}
  assertEquals 0 $?
}

function test_rdp_auth() {
  # 1: GET instance/password
  instance_password="$(run_cmd instance show_password ${instance_uuid})"
  assertEquals 0 $?

  echo "${instance_password}"
  # ---
  # :id: i-czulsyoj
  # :encrypted_password: |
  #  IAAMQn+4axLf/EO+dzQWhzDOBY/dkOCvDegiL8eS1VTs9MrwgA05vnCQ//EO
  #  RaZPfWQLV4qhIjr1h4RUNQZ41Hs22lOztb2qpACuQzlfXpTKDp3YhZdOw/V8
  #  hencQ02g8uziV5+Wpy1DLikkATMrRLurp2zsg7XQp/0mO9e16YzkzO9Xor3R
  #  C+daGS/YeB8BZqQbwZgzWLnrgRm7q6zzKJoGxl67+RYHki/19n1gFQXNVyOi
  #  /gZo1sdAPF/N2a18naOM4lpbjRr4R2u82mkgCMFYzRJew9yvOTGkFhwZamkX
  #  9j+wU5Cvo0fDDpS4pXlRTvbmu9ESTmg0tSfFyuCgkA==

  # 2: get encrypted_password value
  instance_password="$(echo "${instance_password}" | egrep '^  ' | sed 's,^  ,,')"
  [[ -n "${instance_password}" ]]
  assertEquals 0 $?

  # 3: private key exists?
  [[ -f "${ssh_key_pair_path}" ]]
  assertEquals 0 $?

  # 4: decrypt password
  echo "ssh_key_pair_path='${ssh_key_pair_path}'"
  cat "${ssh_key_pair_path}"
  plain_password="$(echo "${instance_password}" | base64 --decode | openssl rsautl -decrypt -inkey "${ssh_key_pair_path}" -oaep)"
  [[ -n "${plain_password}" ]]

  echo "plain_password='${plain_password}'"

  # 5: rdp auth
  rdp_auth -u "${rdp_user}" -p "${plain_password}" "${instance_ipaddr}"
  assertEquals 0 $?
}

## shunit2

. ${shunit2_file}
