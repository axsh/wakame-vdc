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
Version: 12.03
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
BuildRequires: rpm-build
BuildRequires: createrepo
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
BuildRequires: mysql-devel
BuildRequires: chrpath
BuildRequires: pkgconfig
# Ruby binary build dependency
BuildRequires: readline-devel ncurses-devel openssl-devel libxml2-devel libxslt-devel gdbm-devel zlib-devel
# vmapp dependency
BuildRequires: parted
# build local cache
BuildRequires: yum-utils
# Trema/racket gem build dependency
BuildRequires: sqlite-devel libpcap-devel

# * wakame-vdc(common)
Requires: openssh-server openssh-clients
Requires: curl
Requires: nc
Requires: mysql
Requires: initscripts
Requires: logrotate
Requires: flog
Requires: ntp
Requires: ntpdate
Requires: gzip
Requires: tar
Requires: file
Requires: prelink
# Ruby binary dependency
Requires: libxml2 libxslt readline openssl ncurses-libs gdbm zlib
Requires: jemalloc
# for erlang, rabbitmq-server
# Requires: epel-release-6-x
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
Requires: nginx
Requires: dnsmasq
%description dcmgr-vmapp-config
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
Requires: kmod-openvswitch
Requires: openvswitch
Requires: kpartx
Requires: libcgroup
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
Requires: lxc
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

# vdcsh
%package vdcsh
BuildArch: noarch
Summary: vdcsh
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description vdcsh
<insert long description, indented with spaces>

# tests-cucumber
%package tests-cucumber
Summary: tests-cucumber
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
%description tests-cucumber
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

components="
 dcmgr
 frontend
 rpmbuild
 client
"
for component in ${components}; do
  rsync -aHA --exclude=".git/*" --exclude="*~" `pwd`/${component} ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/
done
unset components

rsync -aHA %{prefix}/%{oname}/ruby ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/

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
[ -d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/cucumber ] || mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/cucumber
rsync -aHA `pwd`/tests/vdc.sh   ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/
rsync -aHA `pwd`/tests/vdc.sh.d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/
rsync -aHA `pwd`/tests/builder/functions.sh ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder/functions.sh
rsync -aHA `pwd`/tests/cucumber ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/

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

%files
%defattr(-,root,root)
%{prefix}/%{oname}/
%config /etc/logrotate.d/flog-vdc
%config /etc/init.d/vdc-net-event
%config(noreplace) /etc/default/wakame-vdc
%config /etc/prelink.conf.d/wakame-vdc.conf
%dir /etc/%{oname}/
%dir /var/log/%{oname}
%dir /var/lib/%{oname}
%exclude %{prefix}/%{oname}/tests/

%files vdcsh
%defattr(-,root,root)
%{prefix}/%{oname}/tests/vdc.sh
%{prefix}/%{oname}/tests/vdc.sh.d/
%{prefix}/%{oname}/tests/builder/
%dir %{prefix}/%{oname}/tests
%attr(0600, root, root) %{prefix}/%{oname}/tests/vdc.sh.d/pri.pem

%files tests-cucumber
%defattr(-,root,root)
%dir %{prefix}/%{oname}/tests/cucumber
%{prefix}/%{oname}/tests/cucumber/

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
%config(noreplace) /etc/default/vdc-metadata
%config(noreplace) /etc/default/vdc-nsa
%config(noreplace) /etc/default/vdc-sta
%config(noreplace) /etc/default/vdc-webui
%config(noreplace) /etc/default/vdc-proxy
%config(noreplace) /etc/default/vdc-auth
%config(noreplace) /etc/default/vdc-nwmongw
%config /etc/init/vdc-dcmgr.conf
%config /etc/init/vdc-collector.conf
%config /etc/init/vdc-metadata.conf
%config /etc/init/vdc-nsa.conf
%config /etc/init/vdc-sta.conf
%config /etc/init/vdc-webui.conf
%config /etc/init/vdc-proxy.conf
%config /etc/init/vdc-auth.conf
%config /etc/init/vdc-nwmongw.conf
%dir /etc/%{oname}/dcmgr_gui
%dir /etc/%{oname}/convert_specs
%dir /var/log/%{oname}/dcmgr_gui
%dir /var/lib/%{oname}/images
%dir /var/lib/%{oname}/volumes
%dir /var/lib/%{oname}/snap

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
%config /etc/sysctl.d/30-bridge-if.conf
%dir /var/lib/%{oname}/instances
%dir /var/lib/%{oname}/instances/tmp

%files hva-kvm-vmapp-config

%files hva-lxc-vmapp-config

%files hva-openvz-vmapp-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-openvz.conf

%files hva-full-vmapp-config

%changelog
