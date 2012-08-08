#!/bin/bash

#rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
yum -y install haproxy
yum -y install stunnel
chkconfig haproxy off
chkconfig stunnel off
rm -f /etc/haproxy/haproxy.cfg

exit 0
