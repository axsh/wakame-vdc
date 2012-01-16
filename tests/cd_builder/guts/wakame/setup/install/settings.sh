#!/bin/bash

export GEM_HOME=/home/wakame/.gem/ruby/1.8
export GEM_PATH=${GEM_HOME}
export PATH=${PATH}:${GEM_HOME}/bin

images_cd_path="/cdrom/setup/images"
images=( "ubuntu-10.04_with-metadata_kvm_i386.raw.gz" )
prefix_path=/usr/share/axsh/wakame-vdc
log_file=${prefix_path}/installer.log
#${prefix_path}/setup.sh >> ${log_file}

#Setup bridged networking
${prefix_path}/bridge_up.sh

#Set proper kernel network settings
cd /etc
[ -f sysctl.conf ] && {
  cp -p sysctl.conf sysctl.conf.`date +%Y%m%d-%H%M%S`
}
echo "# common nat
net.ipv4.ip_forward=1
net.ipv4.conf.default.rp_filter=0
net.ipv4.ip_dynaddr=0
net.ipv4.tcp_syncookies=0
net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_ignore_bogus_error_responses=0

# any nics
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1

# conntrack
net.netfilter.nf_conntrack_acct=1" > sysctl.conf

# Copy images
[ -d ${prefix_path}/tmp ] || mkdir -p ${prefix_path}/tmp
[ -d ${prefix_path}/tmp/images ] || mkdir -p ${prefix_path}/tmp/images
for image in ${images[@]}; do
  if [ -f ${images_cd_path}/${image} ]; then
    cp ${images_cd_path}/${image} ${prefix_path}/tmp/images/${image}
    #gunzip ${image}
  fi
done
