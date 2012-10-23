Filesystem Hierarchy : wakame-vdc-dcmgr-vmapp-config-
====================================================

/etc/default : Host-specific dcmgr configuration
------------------------------------------------

+ /etc/default/vdc-auth
+ /etc/default/vdc-collector
+ /etc/default/vdc-dcmgr
+ /etc/default/vdc-metadata
+ /etc/default/vdc-nsa
+ /etc/default/vdc-proxy
+ /etc/default/vdc-sta
+ /etc/default/vdc-webui
+ /etc/default/vdc-admin

/etc/init : Upstart system job configuration
--------------------------------------------

+ /etc/init/vdc-auth.conf
+ /etc/init/vdc-collector.conf
+ /etc/init/vdc-dcmgr.conf
+ /etc/init/vdc-metadata.conf
+ /etc/init/vdc-nsa.conf
+ /etc/init/vdc-proxy.conf
+ /etc/init/vdc-sta.conf
+ /etc/init/vdc-webui.conf
+ /etc/init/vdc-admin.conf

/etc/wakame-vdc : Dcmgr configuration
-------------------------------------

+ /etc/wakame-vdc/convert_specs/
+ /etc/wakame-vdc/dcmgr_gui/
+ /etc/wakame-vdc/admin/
+ /etc/wakame-vdc/unicorn-common.conf

/var/lib/wakame-vdc : Variable state information (optional)
-----------------------------------------------------------

+ /var/lib/wakame-vdc/images/
+ /var/lib/wakame-vdc/snap/
+ /var/lib/wakame-vdc/volumes/

/var/log/wakame-vdc : Log file
------------------------------

+ /var/log/wakame-vdc/collector.log
+ /var/log/wakame-vdc/dcmgr.log
+ /var/log/wakame-vdc/dcmgr_gui/development.log
+ /var/log/wakame-vdc/sta.log
+ /var/log/wakame-vdc/proxy.log
+ /var/log/wakame-vdc/webui.log
+ /var/log/wakame-vdc/admin.log
