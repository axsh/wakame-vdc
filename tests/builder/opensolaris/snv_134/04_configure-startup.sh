#!/bin/sh

export LANG=C
export LC_ALL=C
export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin:/bin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT

gem_path=/export/home/wakame/.gem/ruby/1.8
wakame_vdc_version=10.11.0
web_api_uri=http://localhost:9001/
amqp_server_uri=amqp://localhost/


cat <<EOS > /etc/init.d/vdc-agents-sta
#!/bin/sh

export LANG=C
export LC_ALL=C
export GEM_PATH=${gem_path}

wakame_vdc_version=${wakame_vdc_version}
amqp_server_uri=${amqp_server_uri}
log_path=/var/log/vdc-agents-sta.log


case \$1 in
  start)
    cd \${GEM_PATH}/gems/wakame-vdc-agents-\${wakame_vdc_version}/ \
    && nohup \${GEM_PATH}/bin/sta -s \${amqp_server_uri} >> \${log_path} &
    ;;

  stop)
    pid=\`ps awx | egrep 'bin/[s]ta' | awk '{print \$1}'\`
    echo pid: \${pid}
    [ -z "\${pid}" ] || {
      kill \${pid}
    }
    ;;

  *)
    echo "\$0 [ start | stop ]" >&2
    exit 1
    ;;
esac


exit 0
EOS

chmod +x /etc/init.d/vdc-agents-sta



exit 0
