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

# dcmgr-vmapp-config
%package dcmgr-vmapp-config
BuildArch: noarch
Summary: Configuration set for dcmgr VM appliance
Group: Development/Languages
Requires: %{oname} = %{version}-%{release}
Requires: mysql-server
Requires: erlang
Requires: rabbitmq-server
Requires: nginx
Requires: dnsmasq
%description dcmgr-vmapp-config
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
BuildArch: noarch
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
Requires: vzkernel
Requires: vzctl
Requires: kmod-openvswitch-vzkernel
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

# /etc/sysctl.d
[ -d ${RPM_BUILD_ROOT}/etc/sysctl.d ] || mkdir -p ${RPM_BUILD_ROOT}/etc/sysctl.d
rsync -aHA `pwd`/contrib/etc/sysctl.d/*.conf ${RPM_BUILD_ROOT}/etc/sysctl.d/

[ -d ${RPM_BUILD_ROOT}/etc/%{oname} ]               || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}
[ -d ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui ]     || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui
[ -d ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs ] || mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs

# rails app config
ln -s /etc/%{oname}/dcmgr_gui/database.yml           ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/database.yml
ln -s /etc/%{oname}/dcmgr_gui/instance_spec.yml      ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/instance_spec.yml
ln -s /etc/%{oname}/dcmgr_gui/dcmgr_gui.yml          ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/dcmgr_gui.yml
ln -s /etc/%{oname}/dcmgr_gui/load_balancer_spec.yml ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/config/load_balancer_spec.yml
#
ln -s /etc/%{oname}/convert_specs/load_balancer.yml  ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/dcmgr/config/convert_specs/load_balancer.yml

# vdcsh
[ -d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/vdc.sh.d ] || mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/vdc.sh.d
[ -d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder  ] || mkdir -p ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder
rsync -aHA `pwd`/tests/vdc.sh   ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/
rsync -aHA `pwd`/tests/vdc.sh.d ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/
rsync -aHA `pwd`/tests/builder/functions.sh ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tests/builder/functions.sh

# log directory
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{oname}
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{oname}/dcmgr_gui
ln -s /var/log/%{oname}/dcmgr_gui ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/frontend/dcmgr_gui/log

# tmp directory
ln -s /var/lib/%{oname}/tmp ${RPM_BUILD_ROOT}/%{prefix}/%{oname}/tmp

# lib directory
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp/instances
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp/instances/tmp
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp/images
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp/volumes
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{oname}/tmp/snap

%clean
RUBYDIR=%{prefix}/%{oname}/ruby rpmbuild/rules clean
rm -rf %{prefix}/%{oname}/ruby
rm -rf ${RPM_BUILD_ROOT}

%post
/sbin/chkconfig       ntpd on
/sbin/chkconfig       ntpdate on
/sbin/chkconfig --add vdc-net-event

%post debug-config
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-dump-core.conf

%post dcmgr-vmapp-config
/sbin/chkconfig --add mysqld
/sbin/chkconfig       mysqld on
/sbin/chkconfig --add rabbitmq-server
/sbin/chkconfig       rabbitmq-server on

%post hva-common-vmapp-config
/sbin/chkconfig --del iptables
/sbin/chkconfig --del ebtables
/sbin/chkconfig --add iscsi
/sbin/chkconfig       iscsi  on
/sbin/chkconfig --add iscsid
/sbin/chkconfig       iscsid on
/sbin/chkconfig --add tgtd
/sbin/chkconfig       tgtd on
%{prefix}/%{oname}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-bridge-if.conf
%{prefix}/%{oname}/rpmbuild/helpers/add-loopdev.sh
%{prefix}/%{oname}/rpmbuild/helpers/set-openvswitch-conf.sh

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
%dir /var/lib/%{oname}/tmp
%exclude %{prefix}/%{oname}/tests/

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
%config /etc/init/vdc-dcmgr.conf
%config /etc/init/vdc-collector.conf
%config /etc/init/vdc-metadata.conf
%config /etc/init/vdc-nsa.conf
%config /etc/init/vdc-sta.conf
%config /etc/init/vdc-webui.conf
%config /etc/init/vdc-proxy.conf
%config /etc/init/vdc-auth.conf
%config /etc/wakame-vdc/unicorn-common.conf
%dir /etc/%{oname}/dcmgr_gui
%dir /etc/%{oname}/convert_specs
%dir /var/log/%{oname}/dcmgr_gui
%dir /var/lib/%{oname}/tmp/images
%dir /var/lib/%{oname}/tmp/volumes
%dir /var/lib/%{oname}/tmp/snap

%files hva-common-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hva
%config /etc/init/vdc-hva.conf
%config /etc/init/vdc-hva-worker.conf
%config /etc/sysctl.d/30-bridge-if.conf
%dir /var/lib/%{oname}/tmp/instances

%files hva-kvm-vmapp-config

%files hva-lxc-vmapp-config

%files hva-openvz-vmapp-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-openvz.conf

%files hva-full-vmapp-config

%changelog
