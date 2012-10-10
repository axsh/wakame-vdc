#!/bin/bash
#
# Ubuntu 10.04 LTS
#

set -e

# Trema install.
work_dir=${work_dir:?"work_dir needs to be set"}

if [ ! -d $work_dir/trema/.git ]; then
    cd $work_dir
    git clone git://github.com/axsh/trema
    cd ./trema/
    bundle install
    svn co svn://rubyforge.org/var/svn/rant
    (cd rant/trunk/ && ruby ./setup.rb && rant package && gem install pkg/rant-0.5.9.gem && cp pkg/rant-0.5.9.gem ${work_dir}/dcmgr/vendor/cache/)
    ruby ./build.rb
    mkdir ./tmp/log || true
fi

# Open vSwitch install.
ovs_build_dir=/tmp/ovs.$$/

mkdir $ovs_build_dir && cd $ovs_build_dir

if [ "$1" = "ovs-wakame" ]; then
    echo "Compiling Open vSwitch from 'wakame-vdc/openvswitch'."
    ovs_build_dir=$work_dir
    cd $work_dir/openvswitch

elif [ "$1" = "ovs-1.2.2" ]; then
    echo "Compiling Open vSwitch 1.2.2."
    curl http://openvswitch.org/releases/openvswitch-1.2.2.tar.gz -o openvswitch-1.2.2.tar.gz
    tar xzf openvswitch-1.2.2.tar.gz
    mv openvswitch-1.2.2 openvswitch
    cd openvswitch
else
    echo "Compiling Open vSwitch 1.6.1."
    curl http://openvswitch.org/releases/openvswitch-1.6.1.tar.gz -o openvswitch-1.6.1.tar.gz
    tar xzf openvswitch-1.6.1.tar.gz
    mv openvswitch-1.6.1 openvswitch
    cd openvswitch
fi

# Allow inclusion of patches to ovs.
for patch_file in $work_dir/tests/openflow/ovs_*.patch; do
    if [ -f "$patch_file" ]; then
        echo "Adding patch file '$patch_file' to ovs-switchd."
        patch -p1 < "$patch_file"
    fi
done

./boot.sh && ./configure --prefix=$work_dir/ovs/ --with-linux=/lib/modules/`uname -r`/build/ > /dev/null
(make && make install) > /dev/null

install --mode=0644 ./datapath/linux/*.ko /lib/modules/`uname -r`/kernel/drivers/net
depmod

cat ./debian/openvswitch-switch.init | sed -e "s:/usr/:$work_dir/ovs/:g" -e "s:### END INIT INFO:### END INIT INFO\n\nBRCOMPAT=yes:" > ./ovs-switch.tmp
install --mode=0755 ./ovs-switch.tmp /etc/init.d/ovs-switch

mkdir $work_dir/ovs/etc/ || true
mkdir $work_dir/ovs/etc/openvswitch || true
mkdir $work_dir/ovs/var/run || true
mkdir $work_dir/ovs/var/run/openvswitch || true

# Initialize the Open vSwitch database.
#
# The default database path is '$PREFX/etc/openvswitch/conf.db', if a
# non-default path is used 'ovs-vswitch <db_path>' will be required
# and 'ovs-vswitch --db=<db_path>'.
cd $work_dir
./ovs/bin/ovsdb-tool create $work_dir/ovs/etc/openvswitch/conf.db $ovs_build_dir/openvswitch/vswitchd/vswitch.ovsschema
./ovs/sbin/ovsdb-server --pidfile --detach --remote=punix:$work_dir/ovs/var/run/openvswitch/db.sock $work_dir/ovs/etc/openvswitch/conf.db
./ovs/bin/ovs-vsctl --no-wait init

[ "$1" != "ovs-wakame" ] && [ -d $ovs_build_dir ] && rm -rf $ovs_build_dir
