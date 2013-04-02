# -*-Shell-script-*-
#
# requires:
#   bash
#

function ssl_output_dir() {
  echo ${1:-${PWD}}
}

function setup_self_signed_key() {
  local common_name=${1:-example.com}
  openssl req -new -newkey rsa:2048 -nodes -keyout $(ssl_output_dir)/${common_name}.key.pem -out $(ssl_output_dir)/${common_name}.csr.pem <<-EOS
	JP
	Tokyo
	Shinjuku
	The Example Software Foundation
	Operation
	${common_name}
	info@${common_name}
	.
	.
	EOS
  openssl x509 -in $(ssl_output_dir)/${common_name}.csr.pem -days 3650 -req -signkey $(ssl_output_dir)/${common_name}.key.pem > $(ssl_output_dir)/${common_name}.crt.pem
}

function teardown_self_signed_key() {
  local common_name=${1:-example.com}
  rm -f $(ssl_output_dir)/${common_name}.*.pem
}
