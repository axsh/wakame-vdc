#!/bin/bash

ZABBIX_VER=$(rpm -qa zabbix-server | awk -F\- '{print $3}')

mysqladmin create zabbix --default-character-set=utf8

mysql -uroot <<EOF
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
flush privileges;
EOF

mysql -uroot zabbix < /usr/share/doc/zabbix-server-${ZABBIX_VER}/schema/mysql.sql
mysql -uroot zabbix < /usr/share/doc/zabbix-server-${ZABBIX_VER}/data/data.sql
mysql -uroot zabbix < /usr/share/doc/zabbix-server-${ZABBIX_VER}/data/images_mysql.sql


touch /root/zabbix-first-boot
