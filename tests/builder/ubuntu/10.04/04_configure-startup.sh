#!/bin/sh

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT

gem_path=/home/wakame/.gem/ruby/1.8
vdc_version=10.11.0
amqp_server_uri=amqp://localhost/
web_api_port=9001
#web_metadata_port=9002
webui_port=9000

cat <<EOS > /etc/init/vdc-agents-hva.conf
start on runlevel [2345]
stop on runlevel [06]

chdir ${gem_path}/gems/wakame-vdc-agents-${vdc_version}/
exec env - PATH=/bin:/usr/bin:/sbin:/usr/sbin GEM_HOME=${gem_path} GEM_PATH=${gem_path} ${gem_path}/bin/hva -s ${amqp_server_uri} >>/var/log/vdc-agents-hva.log 2>&1
EOS

cat <<EOS > /etc/init/vdc-agents-nsa.conf
start on runlevel [2345]
stop on runlevel [06]

chdir ${gem_path}/gems/wakame-vdc-agents-${vdc_version}/
exec env - PATH=/bin:/usr/bin:/sbin:/usr/sbin GEM_HOME=${gem_path} GEM_PATH=${gem_path} ${gem_path}/bin/nsa -s ${amqp_server_uri} >>/var/log/vdc-agents-nsa.log 2>&1
EOS

cat <<EOS > /etc/init/vdc-dcmgr-collector.conf
start on runlevel [2345]
stop on runlevel [06]

exec env - PATH=/bin:/usr/bin:/sbin:/usr/sbin GEM_HOME=${gem_path} GEM_PATH=${gem_path} ${gem_path}/bin/collector >>/var/log/vdc-dcmgr-collector.log 2>&1
EOS

cat <<EOS > /etc/init/vdc-dcmgr-web-api.conf
start on runlevel [2345]
stop on runlevel [06]

chdir ${gem_path}/gems/wakame-vdc-dcmgr-${vdc_version}/web/api/
exec env - PATH=/bin:/usr/bin:/sbin:/usr/sbin GEM_HOME=${gem_path} GEM_PATH=${gem_path} ${gem_path}/bin/rackup -p ${web_api_port} ./config.ru >>/var/log/vdc-dcmgr-web-api.log 2>&1
EOS

cat <<EOS > /etc/init/vdc-webui.conf
start on runlevel [2345]
stop on runlevel [06]

chdir ${gem_path}/gems/wakame-vdc-webui-${vdc_version}/config/
exec env - PATH=/bin:/usr/bin:/sbin:/usr/sbin GEM_HOME=${gem_path} GEM_PATH=${gem_path} ${gem_path}/bin/rackup -p ${webui_port} ../config.ru >>/var/log/vdc-webui.log 2>&1
EOS

exit 0
