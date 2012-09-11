#!/bin/bash

routing_key=$2
message=$3

stunnel_private_key="/etc/stunnel/key.pem"
stunnel_public_key="/etc/stunnel/cert.pem"
stunnel_conf="/etc/stunnel/stunnel.conf"
haproxy_conf="/etc/haproxy/haproxy.cfg"

head=`cat ${message} | sed -n '1,/^ $/p'| openssl enc -d -base64`
body=`cat ${message} | sed '1,/^ $/d'| openssl enc -d -base64`

case "${head}" in
  "write:private_key")
    echo "$body" > ${stunnel_private_key}
    chmod 600 ${stunnel_private_key}
  ;;
  "write:public_key")
    echo "$body" > ${stunnel_public_key}
    chmod 600 ${stunnel_public_key}
  ;;
  "start:stunnel")
    [ -f ${stunnel_private_key} ] && [ -f ${stunnel_public_key} ] && {
      echo "$body" > ${stunnel_conf}
      service stunnel start
      chkconfig stunnel on
    }
  ;;
  "reload:stunnel")
    echo "$body" > ${stunnel_conf}
    if [ "`service stunnel status`" = 'stunnel is stopped' ]; then
      service stunnel start
    else
      service stunnel reload
    fi
    chkconfig stunnel on
  ;;
  "stop:stunnel")
    service stunnel stop
    chkconfig stunnel off
  ;;
  "start:haproxy")
    echo "$body" > ${haproxy_conf}
    service haproxy start
    chkconfig haproxy on
  ;;
  "reload:haproxy")
    echo "$body" > ${haproxy_conf}
    if [ "`service haproxy status`" = 'haproxy is stopped' ]; then
      service haproxy start
    else
      service haproxy reload
    fi
    chkconfig haproxy on
  ;;
esac

exit 0
