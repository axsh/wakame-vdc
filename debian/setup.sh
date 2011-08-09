#!/usr/bin/env bash

set -e

account_id="a-shpoolxx"

function gen_oauth() {
  echo ... rake oauth:create_consumer[${account_id}]
  local oauth_keys=$(rake oauth:create_consumer[${account_id}] | egrep -v '^\(in')
  eval ${oauth_keys}

  cat <<EOS > ./oauth_client.rb
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup(:default)
rescue Exception
end

require 'oauth'

consumer_key = "${consumer_key}"
secret_key = "${secret_key}"
site = "http://${proxy_bind:-127.0.0.1}:${proxy_port}"
consumer = OAuth::Consumer.new(consumer_key,secret_key, {:site=>site, :version=>'1.0'})
req = "/api/netfilter_groups"
res = consumer.request(:get, req, nil, {}, {'X-VDC-ACCOUNT-UUID' => '${account_id}'})
p res.body
EOS
  chmod +x ./oauth_client.rb
}

prefix_path=/usr/share/axsh/wakame-vdc
#export GEM_HOME=${prefix_path}/gem/ruby/1.8
#export GEM_PATH=${GEM_HOME}
#export PATH=${PATH}:${GEM_HOME}/bin

  #cat <<'EOS' > ~/.gemrc
#---
#:benchmark: false
#gem: --no-rdoc --no-ri
#:update_sources: true
#:verbose: true
#:backtrace: false
#:sources:
#- http://gems.rubyforge.org/
#- http://gems.github.com
#:bulk_threshold: 1000
#gemhome: /usr/share/axsh/wakame-vdc/gem/ruby/1.8
#gempath:
#- /usr/share/axsh/wakame-vdc/gem/ruby/1.8

#EOS
    	
    	#cd ${prefix_path}/gems
    	#for gem in `ls`; do gem install ${gem}; done
    	
      #Give the directory to the wakame user
    	#chown wakame -R /usr/share/axsh/wakame-vdc
    	
      #Take care of the gem dependencies
    	cd ${prefix_path}
    	gem install bundler-1.0.15.gem
    	
    	cd ${prefix_path}/dcmgr
    	bundle install

    	cd ${prefix_path}/frontend/dcmgr_gui
    	bundle install
      
      #getent group  wakame >/dev/null || {
        #groupadd wakame
     # }

      #getent passwd wakame >/dev/null || {
        #useradd -d /home/wakame -s /bin/bash -g wakame -m wakame
      #}
      
      #passwd wakame
      #expect "New password:" 
      #send "wakame\r" 

      #expect "Re-type new password:" 
      #send "wakame\r"
      
      if [[ ! `service mysql status` == *mysql\ start/running*  ]]; then
        service mysql start
      fi;
      
      dbnames="wakame_dcmgr wakame_dcmgr_gui"
      for dbname in ${dbnames}; do
          if [ -z "`mysql -uroot -e "SHOW DATABASES LIKE '$dbname'"`" ]; then
            mysqladmin -uroot create ${dbname}
            #TODO: do this check in a better way
            if [ $dbname == "wakame_dcmgr" ]; then
              cd ${prefix_path}/dcmgr
              rake db:init
            fi
            if [ $dbname == "wakame_dcmgr_gui" ]; then
              cd ${prefix_path}/frontend/dcmgr_gui
              rake db:init db:sample_data admin:generate_i18n oauth:create_table
            fi
          fi
      done

      #Setup Generate oauth
      cd ${prefix_path}/frontend/dcmgr_gui
      gen_oauth
      echo "oauth generated"

      #Setup host network
      #Let's try doing this in the post installation script instead
      #${prefix_path}/bridge_up.sh

      #Setup wakame's network
      echo "Network setup"
      ${prefix_path}/network_setup.sh

      #Put demo data in the database
      echo "Demo data setup"
      ${prefix_path}/demo_data_setup.sh
      
      #Set proper kernel network settings
      #cd /etc
      #[ -f sysctl.conf ] && {
        #cp -p sysctl.conf sysctl.conf.`date +%Y%m%d-%H%M%S`
      #}
      #cp ${prefix_path}/tests/builder/conf/sysctl.conf .
      
      #Setup hva.conf
      echo "Setting up hva.conf"
      cd ${prefix_path}/dcmgr/config
      cp hva.conf.example hva.conf
      
      #Set the right ifindex in hva.conf
      echo "Setting primary ifindex"
      prim_interface=`grep "# The primary network interface" -A 1 /etc/network/interfaces | tail -n 1 | cut -d ' ' -f2`
      prim_ifindex=`cat /sys/class/net/${prim_interface}/ifindex`
      sed -i 's/config.hv_ifindex.*/config.hv_ifindex = '${prim_ifindex}'/' hva.conf
      
      #Set the vm data directory
      echo "Setting the vm data directory"
      vm_data_dir="${prefix_path}/vm"
      mkdir -p ${vm_data_dir}
      sed -i 's@config.vm_data_dir.*@config.vm_data_dir = "'${vm_data_dir}'"@' hva.conf
      
      #Create log files
      echo "Creating log files"
      mkdir -p ${prefix_path}/tmp
      touch ${prefix_path}/tmp/vdc-auth.log
      touch ${prefix_path}/tmp/vdc-collector.log
      touch ${prefix_path}/tmp/vdc-nsa.log
      touch ${prefix_path}/tmp/vdc-hva.log
      touch ${prefix_path}/tmp/vdc-metadata.log
      touch ${prefix_path}/tmp/vdc-api.log
      touch ${prefix_path}/tmp/vdc-auth.log
      touch ${prefix_path}/tmp/vdc-webui.log
exit 0
