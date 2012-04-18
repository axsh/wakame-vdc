%define _prefix_path usr/share/axsh
%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git

Name: wakame-vdc
Version: current
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
#Requires: wakame-vdc
#Requires: qemu-kvm
#[TODO] Requires: lxc

# * wakame-vdc-dcmgr-vmapp-config
#Requires: wakame-vdc
Requires: mysql-server
Requires: erlang
Requires: rabbitmq-server
Requires: nginx
Requires: dnsmasq

# * wakame-vdc-hva-vmapp-config
#Requires: wakame-vdc
Requires: ebtables iptables ethtool vconfig
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
# TODO
# + enable mysql,rabbitmq-server,tgtd(sta)
# + disable iptables,ip6tables,ebtables
%description dcmgr-vmapp-config
<insert long description, indented with spaces>

# hva-vmapp-config
%package hva-vmapp-config
Summary: Configuration set for hva VM appliance
Group: Development/Languages

%description  hva-vmapp-config
<insert long description, indented with spaces>

## rpmbuild -bp
%prep
[ -d %{name}-%{version} ] || {
  [ -d %{name} ] || git clone %{_vdc_git_uri}
  mv %{name} %{name}-%{version}
}
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

rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/dcmgr    ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/frontend ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/ruby     ${RPM_BUILD_ROOT}/%{prefix}/%{name}/

[ -d ${RPM_BUILD_ROOT}/etc ] || mkdir -p ${RPM_BUILD_ROOT}/etc
rsync -avx `pwd`/contrib/etc/default     ${RPM_BUILD_ROOT}/etc/
rsync -avx `pwd`/contrib/etc/init        ${RPM_BUILD_ROOT}/etc/
rsync -avx `pwd`/contrib/etc/logrotate.d ${RPM_BUILD_ROOT}/etc/

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%{prefix}/%{name}/
%dir %{prefix}/%{name}/
%config /etc/logrotate.d/flog-vdc

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

%files hva-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hva
%config /etc/init/vdc-hva.conf

%changelog
