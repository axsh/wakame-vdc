#!/bin/bash
#
# Ubuntu 10.04 LTS
#

set -e

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
VDC_ROOT=${VDC_ROOT:?"VDC_ROOT needs to be set"}

# Read dependency information from debian/control.
# % cat debian/control | debcontrol_depends
function debcontrol_depends() {
  # 1. convert comma list to line list.
  # 2. remove trailing spaces.
  # 3. remove debian meta variables. i.e. ${shlib:Depends}
  # 4. remove version conditions.
  # 5. remove wakame-vdc packages.
  awk -F: '$1 == "Depends" || $1 == "Build-Depends" { print substr($0, length($1)+2)}' | \
    sed -e 's|\s*,\s*|\n|g' | \
    sed -e 's/^[ ]*//g' -e 's/[ ]*$//' | \
    sed -e '/\$/d' | \
    sed  -e 's|[\(].*[\)]||g' | \
    uniq | \
    egrep -v '^wakame-vdc'
}

## Install depend packages
# if someone use different release, they want to modify this conf manually. so check if it exists.
[[ -f /etc/apt/apt.conf.d/99default-release ]] || cp $VDC_ROOT/debian/config/apt/99default-release /etc/apt/apt.conf.d/
# force overwrite other apt confs.
cp $VDC_ROOT/debian/config/apt/wakame-vdc.list /etc/apt/sources.list.d/
cp $VDC_ROOT/debian/config/apt/99wakame-vdc /etc/apt/preferences.d/

# debian packages
apt-get update
apt-get -y upgrade
cat ${VDC_ROOT}/debian/control | debcontrol_depends | xargs apt-get -y --force-yes install

# debian/rules installs local ruby binary and bundle install using the binary.
(
  cd $VDC_ROOT
  # skip if build-stamp file exists
  [[ -f build-stamp ]] || {
    ./debian/rules clean
    ./debian/rules build
  }

  cd $VDC_ROOT/tests/cucumber
  bundle install --path=vendor/bundle
)


# prepare configuration files

# dcmgr
(
  cd ${VDC_ROOT}/dcmgr/config/
  cp -f dcmgr.conf.example dcmgr.conf
  cp -f snapshot_repository.yml.example snapshot_repository.yml
#cp -f hva.conf.example hva.conf
  cp -f nsa.conf.example nsa.conf
  cp -f sta.conf.example sta.conf
  
# dcmgr:hva
  cat <<EOS > hva.conf
#------------------------
# Configuration file for hva.
#------------------------

# directory to store VM local data.
config.vm_data_dir = "${VDC_ROOT}/tmp/instances"

# Decides what kind of edge networking will be used. If omitted, the default 'netfilter' option will be used
# * 'netfilter'
# * 'legacy_netfilter' #no longer supported, has issues with multiple vnic vm isolation
# * 'openflow' #experimental, requires additional setup
# * 'off'
config.edge_networking = 'netfilter'

# netfilter and openflow
config.enable_ebtables = true
config.enable_iptables = true
config.enable_subnet = false
config.enable_gre = true

# physical nic index
config.hv_ifindex      = 2 # ex. /sys/class/net/eth0/ifindex => 2

# bridge device name prefix
config.bridge_prefix   = 'br'

# bridge device name novlan
config.bridge_novlan   = 'br0'

# display netfitler commands
config.verbose_netfilter = false
config.verbose_openflow  = false

# netfilter log output flag
config.packet_drop_log = false

# debug netfilter
config.debug_iptables = false

# Use ipset for netfilter
config.use_ipset       = false

# Directory used by Open vSwitch daemon for run files
config.ovs_run_dir = '${VDC_ROOT}/ovs/var/run/openvswitch'

# Path for ovs-ofctl
config.ovs_ofctl_path = '${VDC_ROOT}/ovs/bin/ovs-ofctl'

# Trema base directory
config.trema_dir = '${VDC_ROOT}/trema'
config.trema_tmp = '${VDC_ROOT}/tmp/trema'
EOS
)

# frontend
(
  cd ${VDC_ROOT}/frontend/dcmgr_gui/config/
  cp -f dcmgr_gui.yml.example dcmgr_gui.yml
)


# prepare direcotries under $VDC_ROOT/tmp.
for i in "${VDC_ROOT}/tmp/instances" "${VDC_ROOT}/tmp/snap/" "${VDC_ROOT}/tmp/images/" "${VDC_ROOT}/tmp/volumes/"  "${VDC_ROOT}/tmp/trema/log/" "${VDC_ROOT}/tmp/trema/pid/" "${VDC_ROOT}/tmp/trema/sock/"; do
  [[ -d "$i" ]] || mkdir -p $i
done

# download demo image files.
(
  cd $VDC_ROOT/tmp/images
  
  for meta in $(ls $data_path/image-*.meta); do
    (
      . $meta
      [[ -n "$localname" ]] || {
        localname=$(basename "$uri")
      }
      echo "$(basename ${meta}), ${localname} ..."
      [[ -f "$localname" ]] || {
        # TODO: use HEAD and compare local cached file size
        echo "Downloading image file $localname ..."
        f=$(basename "$uri")
        curl "$uri" > "$f"
        # check if the file name has .gz.
        [[ "$f" == "${f%.gz}" ]] || {
          # gunzip with keeping sparse area.
          zcat "$f" | cp --sparse=always /dev/stdin "${f%.gz}"
        }
        [[ "${f%.gz}" == "$localname" ]] || {
          cp -p --sparse=always "${f%.gz}" "$localname"
        }
        # do not remove .gz as they are used for gzipped file test cases.
      }
    )
  done
)

exit 0
