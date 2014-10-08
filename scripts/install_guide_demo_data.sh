#!/bin/bash

# This script will configure Wakame-vdc to work with OpenVZ instances on a single
# host. It is meant to be used in conjunction with the installation guide on the
# wiki. Please follow the installation guide until it tells you to run this script.
#
# https://github.com/axsh/wakame-vdc/wiki/install-guide

set -e

if [ -z "$NETWORK" ] ||
   [ -z "$PREFIX" ] ||
   [ -z "$DHCP_RANGE_START" ] ||
   [ -z "$DHCP_RANGE_END" ]
then
  cat<<USAGE
  This script requires you to provide the network that you will start instances in.

  The NETWORK and PREFIX environment variabled are required to be set. These
  correspond to the two parts of a cidr notation.
  192.168.0.0/24 would become: NETWORK='192.168.0.0' PREFIX='24'

  Also required are DHCP_RANGE_START and DHCP_RANGE_END. These variables will
  decide which ip addresses Wakame-vdc can use to assign to instances.

  The GATEWAY variable is optional.

  Examples:
  NETWORK='10.0.0.0' PREFIX='8' DHCP_RANGE_START='10.0.0.100' DHCP_RANGE_END='10.0.0.200' ${0}
  NETWORK='192.168.3.0' PREFIX='24' GATEWAY='192.168.3.1' DHCP_RANGE_START='192.168.3.1' DHCP_RANGE_END='192.168.3.254' ${0}
USAGE

  exit 1
fi

set -ue

ruby_path=/opt/axsh/wakame-vdc/ruby/bin
GATEWAY=${GATEWAY:-''}

function uncomment() {
  local commented_line=$1
  local files=$2

  sudo sed -i -e "s/^#\\(${commented_line}\\)/\\1/" ${files}
}

# Put the configuration files in place
sudo cp /opt/axsh/wakame-vdc/dcmgr/config/dcmgr.conf.example /etc/wakame-vdc/dcmgr.conf
sudo cp /opt/axsh/wakame-vdc/dcmgr/config/hva.conf.example /etc/wakame-vdc/hva.conf
sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/database.yml.example /etc/wakame-vdc/dcmgr_gui/database.yml
sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/dcmgr_gui.yml.example /etc/wakame-vdc/dcmgr_gui/dcmgr_gui.yml
sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/instance_spec.yml.example /etc/wakame-vdc/dcmgr_gui/instance_spec.yml
sudo cp /opt/axsh/wakame-vdc/frontend/dcmgr_gui/config/load_balancer_spec.yml.example /etc/wakame-vdc/dcmgr_gui/load_balancer_spec.yml

# Download machine image
sudo mkdir -p /var/lib/wakame-vdc/images
cd /var/lib/wakame-vdc/images
sudo curl -O http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-kvm-md-32.raw.gz

# Set hva node id
uncomment 'NODE_ID=demo1' '/etc/default/vdc-hva'

# Start MySQL so we can set up our databases.
sudo /etc/init.d/mysqld start

# Set up backend database
mysqladmin -uroot create wakame_dcmgr
cd /opt/axsh/wakame-vdc/dcmgr
${ruby_path}/rake db:up

# Fill up the backend database
grep -v '\s*#' <<CMDSET | /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage -e
  # Register the HVA
  host add hva.demo1 \
    --uuid hn-demo1 \
    --display-name "demo hva 1" \
    --cpu-cores 100 \
    --memory-size 10240 \
    --hypervisor openvz \
    --arch x86_64 \
    --disk-space 102400 \
    --force

  # Tell Wakame-vdc that we're storing images on the local file system
  backupstorage add \
    --uuid bkst-local \
    --display-name "local storage" \
    --base-uri "file:///var/lib/wakame-vdc/images/" \
    --storage-type local \
    --description "storage on the local filesystem"

  # Add the image's backup object (hard drive image)
  backupobject add \
    --uuid bo-lucid5d \
    --display-name "Ubuntu 10.04 (Lucid Lynx) root partition" \
    --storage-id bkst-local \
    --object-key ubuntu-lucid-kvm-md-32.raw.gz \
    --size 149084 \
    --allocation-size 359940 \
    --container-format gz \
    --checksum 55dcc87838af4aa14eb3eb986ea756d3

  # Tell Wakame-vdc that this backup object is a bootable machine image
  image add local bo-lucid5d \
    --account-id a-shpoolxx \
    --uuid wmi-lucid5d \
    --root-device uuid:148bc5df-3fc5-4e93-8a16-7328907cb1c0 \
    --display-name "Ubuntu 10.04 (Lucid Lynx)"

  # Give Wakame-vdc a network to start instances in
  network add \
    --uuid nw-demo1 \
    --ipv4-network "${NETWORK}" \
    --prefix "${PREFIX}" \
    --account-id a-shpoolxx \
    --display-name "demo network"

  # Tell Wakame-vdc which ip addresses from the network it can use
  network dhcp addrange nw-demo1 "${DHCP_RANGE_START}" "${DHCP_RANGE_END}"

  # Tell Wakame-vdc which mac addresses it can use
  macrange add 525400 1 ffffff --uuid mr-demomacs

  # Tell Wakame-vdc which bridge to attach nw-demo1's vnics to
  # See /etc/wakame-vdc/hva.conf to see which bridge dcn-public is mapped to
  network dc add public --uuid dcn-public --description "the network instances are started in"
  network forward nw-demo1 public

  # Enable security groups on the public bridge
  network dc add-network-mode public securitygroup
CMDSET

# Add the network gateway if it was set
if [ -n "$GATEWAY" ]; then
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage network modify nw-demo1 --ipv4-gw "$GATEWAY"
fi

# Set up the frontend GUI database
mysqladmin -uroot create wakame_dcmgr_gui
cd /opt/axsh/wakame-vdc/frontend/dcmgr_gui/
${ruby_path}/rake db:init

# Fill it up
/opt/axsh/wakame-vdc/frontend/dcmgr_gui/bin/gui-manage -e <<CMDSET
  account add --name default --uuid a-shpoolxx
  user add --name "demo user" --uuid u-demo --password demo --login-id demo
  user associate u-demo --account-ids a-shpoolxx
CMDSET

# add newline
echo
