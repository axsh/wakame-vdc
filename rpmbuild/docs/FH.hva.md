Filesystem Hierarchy : wakame-vdc-hva-*-vmapp-config
====================================================

/etc/default : Host-specific hva configuration
----------------------------------------------

+ /etc/default/vdc-hva

/etc/init : Upstart system job configuration
--------------------------------------------

+ /etc/init/vdc-hva.conf

/etc : Host-specific system configuration
-----------------------------------------

+ /etc/sysctl.d/30-bridge-if.conf
+ /etc/sysctl.d/30-openvz.conf

/var/lib/wakame-vdc : Variable state information (optional)
-----------------------------------------------------------

+ /var/lib/wakame-vdc/tmp/instances

/var/log/wakame-vdc : Log file
------------------------------

+ /var/log/wakame-vdc/hva.log
