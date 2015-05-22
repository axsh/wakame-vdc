%define _prefix_path opt/axsh
%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git
%define oname wakame-vdc

# * rpmbuild -bb ./wakame-vdc.spec \
# --define "build_id $(../helpers/gen-release-id.sh)"
# --define "build_id $(../helpers/gen-release-id.sh [ commit-hash ])"
# --define "repo_uri git://github.com/axsh/wakame-vdc.git"

%define release_id 1.daily
%{?build_id:%define release_id %{build_id}}
%{?repo_uri:%define _vdc_git_uri %{repo_uri}}

Name: %{oname}
Version: 15.03
Release: %{release_id}%{?dist}
Summary: The wakame virtual data center.
Group: Development/Languages
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://wakame.jp/
Source: %{_vdc_git_uri}
Prefix: /%{_prefix_path}
License: see https://github.com/axsh/wakame-vdc/blob/master/README.md

# Disable automatic dependency analysis.
AutoReqProv: no

# * build
# rpm-build and etc...
BuildRequires: rpmdevtools
BuildRequires: createrepo
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
BuildRequires: mysql-devel
BuildRequires: chrpath
BuildRequires: pkgconfig
# vmapp dependency
BuildRequires: parted
# build local cache
BuildRequires: yum-utils
# Trema/racket gem build dependency
BuildRequires: sqlite-devel libpcap-devel
BuildRequires: v8 v8-devel

# * wakame-vdc(common)
Requires: openssh-server openssh-clients
Requires: curl
Requires: nc
Requires: mysql
Requires: initscripts
Requires: logrotate
Requires: ntp
Requires: ntpdate
Requires: gzip
Requires: tar
Requires: file
Requires: prelink
# Ruby binary dependency
Requires: %{oname}-ruby >= 2.0.0.247
Requires: %{oname}-ruby <  2.0.1
Requires: jemalloc
Requires: parted

# (base)
%description
<insert long description, indented with spaces>

# debug-config
%package debug-config
BuildArch: noarch
Summary: Configuration set for debug
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description debug-config
<insert long description, indented with spaces>

# ha-common-config
%package ha-common-config
BuildArch: noarch
Summary: Configuration set for HA
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: drbd84-utils, kmod-drbd84
Requires: ucarp
%description ha-common-config
<insert long description, indented with spaces>

# ha-rabbitmq-config
%package ha-rabbitmq-config
BuildArch: noarch
Summary: Configuration set for HA rabbitmq
Group: Development/Languages
Requires: %{oname}-ha-common-config = %{version}-%{release}
%description ha-rabbitmq-config
<insert long description, indented with spaces>

# ha-dcmgr-config
%package ha-dcmgr-config
BuildArch: noarch
Summary: Configuration set for HA dcmgr
Group: Development/Languages
Requires: %{oname}-ha-dcmgr-config = %{version}-%{release}
Requires: %{oname}-dcmgr-vmapp-config = %{version}-%{release}
%description ha-dcmgr-config
<insert long description, indented with spaces>

# rack-config
%package rack-config
BuildArch: noarch
Summary: Configuration set for rack
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description rack-config
<insert long description, indented with spaces>

# dcmgr-vmapp-config
%package dcmgr-vmapp-config
BuildArch: noarch
Summary: Configuration set for dcmgr VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: %{oname}-rack-config = %{version}-%{release}
Requires: mysql-server
Requires: erlang
Requires: rabbitmq-server
# dcell
Requires: zeromq3
Requires: zeromq3-devel
%description dcmgr-vmapp-config
<insert long description, indented with spaces>

# webui-vmapp-config
%package webui-vmapp-config
BuildArch: noarch
Summary: Configuration set for webui VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: %{oname}-rack-config = %{version}-%{release}
%description webui-vmapp-config
<insert long description, indented with spaces>

# auth-vmapp-config
%package auth-vmapp-config
BuildArch: noarch
Summary: Configuration set for auth VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: %{oname}-rack-config = %{version}-%{release}
%description auth-vmapp-config
<insert long description, indented with spaces>

# proxy-vmapp-config
%package proxy-vmapp-config
BuildArch: noarch
Summary: Configuration set for proxy VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: httpd
%description proxy-vmapp-config
<insert long description, indented with spaces>

# admin-vmapp-config
%package admin-vmapp-config
BuildArch: noarch
Summary: Configuration set for admin VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: %{oname}-rack-config = %{version}-%{release}
%description admin-vmapp-config
<insert long description, indented with spaces>

# hva-common-vmapp-config
%package hva-common-vmapp-config
BuildArch: noarch
Summary: Configuration set for hva VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: dosfstools
Requires: iscsi-initiator-utils scsi-target-utils
Requires: ebtables iptables ethtool vconfig iproute
Requires: bridge-utils
Requires: dracut-kernel
Requires: kpartx
Requires: libcgroup
Requires: tunctl
Requires: sysstat
# Trema/racket gem binary dependency
Requires: sqlite libpcap
Requires: pv
%description  hva-common-vmapp-config
<insert long description, indented with spaces>

# hypervisor:kvm
%package hva-kvm-vmapp-config
Summary: Configuration set for hva KVM VM appliance
Group: Development/Languages
Requires: %{oname}-hva-common-vmapp-config = %{version}-%{release}
%ifarch x86_64
Requires: qemu-kvm
%endif
%description  hva-kvm-vmapp-config
<insert long description, indented with spaces>

# hypervisor:lxc
%package hva-lxc-vmapp-config
BuildArch: noarch
Summary: Configuration set for hva LXC VM appliance
Group: Development/Languages
Requires: %{oname}-hva-common-vmapp-config = %{version}-%{release}
Requires: lxc >= 1.0.0
%description  hva-lxc-vmapp-config
<insert long description, indented with spaces>

# hypervisor:openvz
%package hva-openvz-vmapp-config
BuildArch: noarch
Summary: Configuration set for hva OpenVZ VM appliance
Group: Development/Languages
Requires: %{oname}-hva-common-vmapp-config = %{version}-%{release}
Requires: vzkernel = 2.6.32-042stab055.16
Requires: vzctl = 3.3-1
Requires: vzctl-lib = 3.3-1
Requires: vzquota = 3.1-1
Requires: ploop = 1.4-1
Requires: ploop-lib = 1.4-1
%description  hva-openvz-vmapp-config
<insert long description, indented with spaces>

# hypervisor:*
%package hva-full-vmapp-config
BuildArch: noarch
Summary: Configuration set for hva OpenVZ VM appliance
Group: Development/Languages
Requires: %{oname}-hva-common-vmapp-config = %{version}-%{release}
Requires: %{oname}-hva-kvm-vmapp-config = %{version}-%{release}
Requires: %{oname}-hva-lxc-vmapp-config = %{version}-%{release}
Requires: %{oname}-hva-openvz-vmapp-config = %{version}-%{release}
%description hva-full-vmapp-config
<insert long description, indented with spaces>

# natbox-vmapp-config
%package natbox-vmapp-config
BuildArch: noarch
Summary: Configuration set for natbox VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: keepalived
Requires: bridge-utils
Requires: kmod-openvswitch >= 1.6.1
Requires: kmod-openvswitch <  1.6.2
Requires: openvswitch      >= 1.6.1
Requires: openvswitch      <  1.6.2
%description  natbox-vmapp-config
<insert long description, indented with spaces>

# bksta-vmapp-config
%package bksta-vmapp-config
BuildArch: noarch
Summary: Configuration set for bksta VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description  bksta-vmapp-config
<insert long description, indented with spaces>

# nsa-vmapp-config
%package nsa-vmapp-config
BuildArch: noarch
Summary: Configuration set for nsa VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: dnsmasq
%description  nsa-vmapp-config
<insert long description, indented with spaces>

# sta-vmapp-config
%package sta-vmapp-config
BuildArch: noarch
Summary: Configuration set for sta VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: pv
%description  sta-vmapp-config
<insert long description, indented with spaces>

# metadata-server-vmapp-config
%package metadata-server-vmapp-config
BuildArch: noarch
Summary: Configuration set for metadata VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description  metadata-server-vmapp-config
<insert long description, indented with spaces>

# nwmongw
%package nwmongw-vmapp-config
BuildArch: noarch
Summary: Configuration set for nwmongw VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description  nwmongw-vmapp-config
<insert long description, indented with spaces>

# dolphin
%package dolphin-vmapp-config
BuildArch: noarch
Summary: Configuration set for dolphin VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description  dolphin-vmapp-config
<insert long description, indented with spaces>

# hma-vmapp-config
%package hma-vmapp-config
BuildArch: noarch
Summary: Configuration set for hma VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description  hma-vmapp-config
<insert long description, indented with spaces>

# vdcsh
%package vdcsh
BuildArch: noarch
Summary: vdcsh
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description vdcsh
<insert long description, indented with spaces>

# client-mussel
%package client-mussel
BuildArch: noarch
Summary: api client
Group: Development/Languages
Requires: curl
%description client-mussel
<insert long description, indented with spaces>

## rpmbuild -bp
%prep
[ -d %{name}-%{version} ] && rm -rf %{name}-%{version}
git clone %{_vdc_git_uri} %{name}-%{version}
cd %{name}-%{version}
[ -z "%{build_id}" ] || {
  build_id=%{build_id}
  git checkout ${build_id##*git}
  unset build_id
} && :

%setup -T -D

## rpmbuild -bc
%build
RUBYDIR=%{prefix}/%{oname}/ruby rpmbuild/rules build

## rpmbuid -bi
%install
# don't run "rpmbuild/rules binary"
CURDIR=${RPM_BUILD_ROOT} rpmbuild/rules binary-arch
# clean ruby-hijiki work dir to build
[ -d `pwd`/client/ruby-hijiki/pkg ] && rm -rf `pwd`/client/ruby-hijiki/pkg

[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/

# TODO: Remove contrib dir excluding contrib/fluentd .
# vendor: bundler-specific directory
components="
 dcmgr
 frontend
 rpmbuild
 client
 dolphin
 contrib
 vendor
 vdc-fluentd
"
for component in ${components}; do
  rsync -aHA --exclude=".git/*" --exclude="*~" --exclude="*/cache/*.gem" --exclude="*/cache/bundler/git/*" `pwd`/${component} ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/
done
unset components

[ -d ${RPM_BUILD_ROOT}/etc ] || mkdir -p ${RPM_BUILD_ROOT}/etc
rsync -aHA `pwd`/contrib/etc/default        ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/init           ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/init.d         ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/logrotate.d    ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/prelink.conf.d ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/wakame-vdc     ${RPM_BUILD_ROOT}/etc/

rsync -aHA `pwd`/rpmbuild/etc/ucarp ${RPM_BUILD_ROOT}/etc/

# /etc/sysctl.d
[ -d ${RPM_BUILD_ROOT}/etc/sysctl.d ] || mkdir -p ${RPM_BUILD_ROOT}/etc/sysctl.d
rsync -aHA `pwd`/contrib/etc/sysctl.d/*.conf ${RPM_BUILD_ROOT}/etc/sysctl.d/

[ -d ${RPM_BUILD_ROOT}/etc/%{oname} ]               || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}
[ -d ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui ]     || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui
[ -d ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs ] || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs
[ -d ${RPM_BUILD_ROOT}/etc/%{oname}/admin ]         || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/admin

# dcmgr
ln -s /etc/%{oname}/convert_specs/load_balancer.yml  ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/dcmgr/config/convert_specs/load_balancer.yml

# rails app config
ln -s /etc/%{oname}/dcmgr_gui/database.yml           ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/database.yml
ln -s /etc/%{oname}/dcmgr_gui/instance_spec.yml      ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/instance_spec.yml
ln -s /etc/%{oname}/dcmgr_gui/dcmgr_gui.yml          ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/dcmgr_gui.yml
ln -s /etc/%{oname}/dcmgr_gui/load_balancer_spec.yml ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/load_balancer_spec.yml

# padrino app config
ln -s /etc/%{oname}/admin/admin.yml     ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/admin/config/admin.yml

# vdcsh
[ -d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/vdc.sh.d ] || mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/vdc.sh.d
[ -d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder  ] || mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder
rsync -aHA `pwd`/tests/vdc.sh   ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/
rsync -aHA `pwd`/tests/vdc.sh.d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/

# log directory
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{oname}
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{oname}/dcmgr_gui
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{oname}/admin
ln -s /var/log/%{oname}/dcmgr_gui ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/log
ln -s /var/log/%{oname}/admin ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/admin/log

# tmp directory
ln -s /var/lib/%{oname}/instances ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/instances
ln -s /var/lib/%{oname}/images ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/images
ln -s /var/lib/%{oname}/volumes ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/volumes
ln -s /var/lib/%{oname}/snap ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/snap

# lib directory
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/instances
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/instances/tmp
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/images
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/volumes
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/snap

# mussel
mkdir -p ${RPM_BUILD_ROOT}/usr/bin
ln -s %{prefix}/%{oname}/client/mussel/bin/mussel ${RPM_BUILD_ROOT}/usr/bin/mussel
rsync -aHA `pwd`/client/mussel/musselrc ${RPM_BUILD_ROOT}/etc/wakame-vdc/musselrc
mkdir -p ${RPM_BUILD_ROOT}/etc/bash_completion.d
ln -s %{prefix}/%{oname}/client/mussel/completion/mussel-completion.bash ${RPM_BUILD_ROOT}/etc/bash_completion.d/mussel

%clean
RUBYDIR=%{prefix}/%{oname}/ruby rpmbuild/rules clean
rm -rf %{prefix}/%{oname}/ruby
rm -rf ${RPM_BUILD_ROOT}

%post
/sbin/chkconfig --add vdc-net-event

# fix trema path
[[ -L /var/lib/%{oname}/trema ]] && rm -f /var/lib/%{oname}/trema
trema_home_realpath=`cd %{prefix}/%{oname}/dcmgr && %{prefix}/%{oname}/ruby/bin/bundle show trema`
[[ -z "${trema_home_realpath}" ]] || ln -fs ${trema_home_realpath} /var/lib/%{oname}/trema

%post debug-config
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-dump-core.conf

%post dcmgr-vmapp-config

%post hva-common-vmapp-config
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-bridge-if.conf
%{prefix}/%{oname}/rpmbuild/helpers/add-loopdev.sh

%post hva-openvz-vmapp-config
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-openvz.conf

%post natbox-vmapp-config
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-natbox.conf

%files
%defattr(-,root,root)
%{prefix}/%{oname}/
%config(noreplace) /etc/logrotate.d/wakame-vdc
%config /etc/init.d/vdc-net-event
%config(noreplace) /etc/default/wakame-vdc
%config /etc/prelink.conf.d/wakame-vdc.conf
%dir /etc/%{oname}/
%dir /var/log/%{oname}
%dir /var/lib/%{oname}
%exclude %{prefix}/%{oname}/tests/
%exclude %{prefix}/%{oname}/client/mussel
%exclude /usr/bin/mussel
%exclude /etc/wakame-vdc/musselrc
%exclude /etc/bash_completion.d/mussel

%files client-mussel
%defattr(-,root,root)
%{prefix}/%{oname}/client/mussel/
/usr/bin/mussel
%config(noreplace) /etc/wakame-vdc/musselrc
%dir /etc/bash_completion.d
/etc/bash_completion.d/mussel

%files vdcsh
%defattr(-,root,root)
%{prefix}/%{oname}/tests/vdc.sh
%{prefix}/%{oname}/tests/vdc.sh.d/
%{prefix}/%{oname}/tests/builder/
%dir %{prefix}/%{oname}/tests
%attr(0600, root, root) %{prefix}/%{oname}/tests/vdc.sh.d/pri.pem

%files debug-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-dump-core.conf

%files ha-common-config
%defattr(-,root,root)
%{prefix}/%{oname}/rpmbuild/helpers/lodrbd.sh
%{prefix}/%{oname}/rpmbuild/helpers/lodrbd-mounter.sh
%dir /etc/ucarp/init-common.d
%dir /etc/ucarp/init-down.d
%dir /etc/ucarp/init-up.d
%dir /etc/ucarp/vip-common.d
%dir /etc/ucarp/vip-down.d
%dir /etc/ucarp/vip-up.d
/etc/ucarp/init-down.d/vip
/etc/ucarp/init-up.d/vip

%files ha-rabbitmq-config
%defattr(-,root,root)
/etc/ucarp/init-common.d/rabbitmq
/etc/ucarp/vip-common.d/rabbitmq
/etc/ucarp/vip-down.d/rabbitmq
/etc/ucarp/vip-up.d/rabbitmq

%files ha-dcmgr-config
%defattr(-,root,root)
/etc/ucarp/vip-common.d/vdc-collector
/etc/ucarp/vip-down.d/vdc-collector
/etc/ucarp/vip-up.d/vdc-collector

%files rack-config
%defattr(-,root,root)
%config /etc/wakame-vdc/unicorn-common.conf

%files dcmgr-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-dcmgr
%config(noreplace) /etc/default/vdc-collector
%config /etc/init/vdc-dcmgr.conf
%config /etc/init/vdc-collector.conf
%dir /etc/%{oname}/convert_specs

%files webui-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-webui
%config /etc/init/vdc-webui.conf
%dir /etc/%{oname}/dcmgr_gui
%dir /var/log/%{oname}/dcmgr_gui

%files auth-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-auth
%config /etc/init/vdc-auth.conf

%files proxy-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-proxy
%config /etc/init/vdc-proxy.conf

%files admin-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-admin
%config /etc/init/vdc-admin.conf
%dir /etc/%{oname}/admin
%dir /var/log/%{oname}/admin

%files hva-common-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hva
%config /etc/init/vdc-hva.conf
%config /etc/init/vdc-hva-worker.conf
%config(noreplace) /etc/default/vdc-fluentd
%config /etc/init/vdc-fluentd.conf
%config /etc/sysctl.d/30-bridge-if.conf
%dir /var/lib/%{oname}/instances
%dir /var/lib/%{oname}/instances/tmp

%files hva-kvm-vmapp-config

%files hva-lxc-vmapp-config

%files hva-openvz-vmapp-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-openvz.conf

%files hva-full-vmapp-config

%files natbox-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-natbox
%config /etc/init/vdc-natbox.conf
%config /etc/sysctl.d/30-natbox.conf

%files bksta-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-bksta
%config /etc/init/vdc-bksta.conf

%files nsa-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-nsa
%config /etc/init/vdc-nsa.conf

%files sta-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-sta
%config /etc/init/vdc-sta.conf
%dir /var/lib/%{oname}/images
%dir /var/lib/%{oname}/volumes
%dir /var/lib/%{oname}/snap

%files metadata-server-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-metadata
%config /etc/init/vdc-metadata.conf

%files nwmongw-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-nwmongw
%config /etc/init/vdc-nwmongw.conf

%files dolphin-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-dolphin
%config /etc/init/vdc-dolphin.conf

%files hma-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hma
%config /etc/init/vdc-hma.conf

%changelog
