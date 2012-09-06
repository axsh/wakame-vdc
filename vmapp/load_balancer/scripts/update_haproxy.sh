#!/bin/bash

while read routing_key message
do
  head=`cat ${message} | sed -n '1,/^ $/p'| openssl enc -d -base64`
  body=`cat ${message} | sed '1,/^ $/d'| openssl enc -d -base64`
  case "${head}" in
    "private_key")
      conf='/etc/stunnel/key.pem'
      echo "$body" > $conf
      chmod 600 $conf
    ;;
    "public_key")
      conf='/etc/stunnel/cert.pem'
      echo "$body" > $conf
      chmod 600 $conf
    ;;
    "stunnel")
      echo "$body" > /etc/stunnel/stunnel.conf
      /etc/init.d/stunnel start
    ;;
    "haproxy")
      echo "$body" > /etc/haproxy/haproxy.cfg
      service haproxy reload
    ;;
  esac
done
exit 0
