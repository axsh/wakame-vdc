#!/usr/bin/env bash
#

OVS_PREFIX=/usr/share/axsh/ovs-switch/
echo "Installing Open vSwitch to '$OVS_PREFIX'."

git clone git://openvswitch.org/openvswitch

cd openvswitch/
./boot.sh
./configure --prefix=$OVS_PREFIX --with-linux=/lib/modules/`uname -r`/build/
make && sudo make install

sudo install --mode=0644 ./datapath/linux/*_mod.ko /lib/modules/`uname -r`/kernel/drivers/net
sudo depmod

cat ./debian/openvswitch-switch.init | sed -e "s:/usr/:$OVS_PREFIX:g" > ./ovs-switch.tmp
sudo install --mode=0755 ./ovs-switch.tmp /etc/init.d/ovs-switch

# Initialize the Open vSwitch database.
#
# The default database path is '$PREFX/etc/openvswitch/conf.db', if a
# non-default path is used 'ovs-vswitch <db_path>' will be required
# and 'ovs-vswitch --db=<db_path>'.
$OVS_PREFIX/bin/ovsdb-tool create $OVS_PREFIX/etc/openvswitch/conf.db ./vswitchd/vswitch.ovsschema

# All Open vSwitch commands use 'punix:', 'ptcp:', 'pssl:', etc for listening sockets.
$OVS_PREFIX/sbin/ovsdb-server --pidfile --detach --remote=punix:$OVS_PREFIX/var/run/openvswitch/db.sock $OVS_PREFIX/etc/openvswitch/conf.db

# Initialize the conf.db once.
$OVS_PREFIX/bin/ovs-vsctl --no-wait init
