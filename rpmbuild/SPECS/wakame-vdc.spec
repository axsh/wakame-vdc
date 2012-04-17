Name: wakame-vdc
Version: current
Release: 1.daily
Summary: The wakame virtual data center.
Group: Development/Languages
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://wakame.jp/
Source: git://github.com/axsh/wakame-vdc.git
Prefix: /usr/share/axsh
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
Requires: flog
Requires: mysql
Requires: iscsi-initiator-utils scsi-target-utils
Requires: initscripts
Requires: dosfstools

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

%description
<insert long description, indented with spaces>

## rpmbuild -bp
%prep
[ -d %{name}-%{version} ] || {
  [ -d %{name} ] || git clone git://github.com/axsh/wakame-vdc.git
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

# via debian/dirs
while read dir; do
  [ -d ${RPM_BUILD_ROOT}/${dir} ] || mkdir -p ${RPM_BUILD_ROOT}/${dir}
done < ./debian/dirs

rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/dcmgr    ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/frontend ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
rsync -avx --exclude=".git/*" --exclude="*~" `pwd`/ruby     ${RPM_BUILD_ROOT}/%{prefix}/%{name}/

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
#%files [sub-package-name]
#%files [sub-package-name] -f [file list]
%defattr(-,root,root)
%{prefix}/%{name}/

%changelog
