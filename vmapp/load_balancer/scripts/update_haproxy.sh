#!/bin/bash

routing_key=$2
message=$3

stud_keys="/etc/stud/certs.pem"
stud_conf="/etc/stud/stud.cfg"
haproxy_conf="/etc/haproxy/haproxy.cfg"

head=`cat ${message} | sed -n '1,/^ $/p'| openssl enc -d -base64`
body=`cat ${message} | sed '1,/^ $/d'| openssl enc -d -base64`

case "${head}" in
  "write:keys")
    echo "$body" > ${stud_keys}
    chmod 600 ${stud_keys}
  ;;
  "start:stud")
    [ -f ${stud_keys} ] && {
      echo "$body" > ${stud_conf}
      start stud
    }
  ;;
  "reload:stud")
    echo "$body" > ${stud_conf}
    if [ "`status stud`" = 'stud stop/waiting' ]; then
      start stud
    else
      restart stud
    fi
  ;;
  "stop:stud")
    stop stud
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
