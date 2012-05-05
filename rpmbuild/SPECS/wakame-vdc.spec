%define _prefix_path opt/axsh
%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git

Name: wakame-vdc
Version: 12.03
Release: 1.daily
Summary: The wakame virtual data center.
Group: Development/Languages
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://wakame.jp/
Source: %{_vdc_git_uri}
Prefix: /%{_prefix_path}
License: see https://github.com/axsh/wakame-vdc/blob/master/README.md
BuildArch: x86_64

# * build
BuildRequires: rpm-build
BuildRequires: createrepo
BuildRequires: make
BuildRequires: gcc-c++ gcc
BuildRequires: git
BuildRequires: mysql-devel
BuildRequires: openssl-devel
BuildRequires: libxml2-devel
BuildRequires: libxslt-devel
BuildRequires: chrpath
BuildRequires: fakeroot

# * wakame-vdc(common)
Requires: openssh-server openssh-clients
Requires: curl
Requires: nc
Requires: mysql
Requires: iscsi-initiator-utils scsi-target-utils
Requires: initscripts
Requires: dosfstools
Requires: logrotate
Requires: flog

# * wakame-vdc-dvd-config
#Requires: qemu-kvm
#[TODO] Requires: lxc

# * no need
## ruby
## ruby-devel
## rubygems

# (base)
%description
<insert long description, indented with spaces>

# dcmgr-vmapp-config
%package dcmgr-vmapp-config
Summary: Configuration set for dcmgr VM appliance
Group: Development/Languages
Requires: %{name} = %{version}-%{release}
#Requires: epel-release-6-5
Requires: mysql-server
Requires: erlang
Requires: rabbitmq-server
Requires: nginx
Requires: dnsmasq
# TODO
# + enable mysql,rabbitmq-server,tgtd(sta)
# + disable iptables,ip6tables,ebtables
%description dcmgr-vmapp-config
<insert long description, indented with spaces>

# hva-vmapp-config
%package hva-vmapp-config
Summary: Configuration set for hva VM appliance
Group: Development/Languages
Requires: %{name} = %{version}-%{release}
Requires: ebtables iptables ethtool vconfig
Requires: qemu-kvm
#[TODO] Requires: lxc
%description  hva-vmapp-config
<insert long description, indented with spaces>

## rpmbuild -bp
%prep
[ -d %{name}-%{version} ] || git clone %{_vdc_git_uri} %{name}-%{version}
cd %{name}-%{version}
%setup -T -D

## rpmbuild -bc
%build
rpmbuild/rules build

## rpmbuid -bi
%install
# don't run "rpmbuild/rules binary"
CURDIR=${RPM_BUILD_ROOT} rpmbuild/rules binary-arch

[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}

# directory list via debian/dirs
sed "s,usr/share/axsh,%{_prefix_path},g" ./debian/dirs | while read dir; do
  [ -d ${RPM_BUILD_ROOT}/${dir} ] || mkdir -p ${RPM_BUILD_ROOT}/${dir}
done

rsync -aHA --exclude=".git/*" --exclude="*~" `pwd`/dcmgr    ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -aHA --exclude=".git/*" --exclude="*~" `pwd`/frontend ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -aHA --exclude=".git/*" --exclude="*~" `pwd`/ruby     ${RPM_BUILD_ROOT}/%{prefix}/%{name}/

[ -d ${RPM_BUILD_ROOT}/etc ] || mkdir -p ${RPM_BUILD_ROOT}/etc
rsync -aHA `pwd`/contrib/etc/default     ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/init        ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/contrib/etc/logrotate.d ${RPM_BUILD_ROOT}/etc/

# unicorn configs
rsync -aHA `pwd`/dcmgr/contrib/unicorn-api.conf ${RPM_BUILD_ROOT}/%{prefix}/%{name}/dcmgr/config/unicorn-dcmgr.conf
rsync -aHA `pwd`/dcmgr/contrib/unicorn-api.conf ${RPM_BUILD_ROOT}/%{prefix}/%{name}/dcmgr/config/unicorn-metadata.conf
rsync -aHA `pwd`/dcmgr/contrib/unicorn-api.conf ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/unicorn-webui.conf

%clean
rm -rf ${RPM_BUILD_ROOT}

%post

%post dcmgr-vmapp-config
/sbin/chkconfig --add mysqld
/sbin/chkconfig       mysqld on
/sbin/chkconfig --add rabbitmq-server
/sbin/chkconfig       rabbitmq-server on
/sbin/chkconfig --add tgtd
/sbin/chkconfig       tgtd on

%post hva-vmapp-config
/sbin/chkconfig --del iptables
/sbin/chkconfig --del ebtables
/sbin/chkconfig --add iscsi
/sbin/chkconfig       iscsi  on
/sbin/chkconfig --add iscsid
/sbin/chkconfig       iscsid on

%files
%defattr(-,root,root)
%{prefix}/%{name}/
%config /etc/logrotate.d/flog-vdc
%config(noreplace) /etc/default/wakame-vdc

%files dcmgr-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-dcmgr
%config(noreplace) /etc/default/vdc-collector
%config(noreplace) /etc/default/vdc-metadata
%config(noreplace) /etc/default/vdc-nsa
%config(noreplace) /etc/default/vdc-sta
%config(noreplace) /etc/default/vdc-webui
%config /etc/init/vdc-dcmgr.conf
%config /etc/init/vdc-collector.conf
%config /etc/init/vdc-metadata.conf
%config /etc/init/vdc-nsa.conf
%config /etc/init/vdc-sta.conf
%config /etc/init/vdc-webui.conf
%config %{prefix}/%{name}/dcmgr/config/unicorn-dcmgr.conf
%config %{prefix}/%{name}/dcmgr/config/unicorn-metadata.conf
%config %{prefix}/%{name}/frontend/dcmgr_gui/config/unicorn-webui.conf

%files hva-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hva
%config /etc/init/vdc-hva.conf

%changelog
