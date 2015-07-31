#!/bin/bash

set -e
set -o pipefail

ssh_private_key=$1
inst_uuid=$2
api_uri=${3:-'http://127.0.0.1:9001'}

if [ -z "$ssh_private_key" ] || [ -z "$inst_uuid" ]; then
cat << __END
USAGE:
  $0 /path/to/ssh/key.pem instance_uuid [webapi ipv4:port]

  for example:
  $0 keys/ssh-hrwimvqn.pem i-8q69fa04
  $0 keys/ssh-hrwimvqn.pem i-8q69fa04 https://mywakameserver:9001

__END
fi

function call_api() {
  curl -s "${api_uri}/api/12.03/instances/${inst_uuid}/password"
}

function decrypt() {
  local key=$1
  local encrypted_base64=$2

  echo "$encrypted_base64" \
    | base64 --decode \
    | openssl rsautl -decrypt -inkey "$key" -oaep
}

password=$(call_api \
  | awk -F '"encrypted_password":"' '{print $2}' \
  | awk -F '"' '{print $1}' \
  | sed 's/\\n/\n/g')

echo $(decrypt "$ssh_private_key" "$password")
