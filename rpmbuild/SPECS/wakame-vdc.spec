%define _prefix_path opt/axsh
%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git

Name: wakame-vdc
Version: 12.03
Release: 1.daily%{?dist}
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
# Ruby binary build dependency
BuildRequires: readline-devel ncurses-devel openssl-devel libxml2-devel libxslt-devel gdbm-devel zlib-devel
# vmapp dependency
BuildRequires: parted
# build local cache
BuildRequires: yum-utils

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
# for erlang, rabbitmq-server
# Requires: epel-release-6-6

# (base)
%description
<insert long description, indented with spaces>

# debug-config
%package debug-config
Summary: Configuration set for debug
Group: Development/Languages
Requires: %{name} = %{version}-%{release}
%description debug-config
<insert long description, indented with spaces>

# dcmgr-vmapp-config
%package dcmgr-vmapp-config
Summary: Configuration set for dcmgr VM appliance
Group: Development/Languages
Requires: %{name} = %{version}-%{release}
Requires: mysql-server
Requires: erlang
Requires: rabbitmq-server
Requires: nginx
Requires: dnsmasq
%description dcmgr-vmapp-config
<insert long description, indented with spaces>

# hva-common-vmapp-config
%package hva-common-vmapp-config
Summary: Configuration set for hva VM appliance
Group: Development/Languages
Requires: %{name} = %{version}-%{release}
Requires: dosfstools
Requires: iscsi-initiator-utils scsi-target-utils
Requires: ebtables iptables ethtool vconfig iproute
Requires: bridge-utils
Requires: dracut-kernel
Requires: kmod-openvswitch
Requires: openvswitch
Requires: kpartx
Requires: libcgroup
# includes /sbin/losetup
Requires: util-linux-ng
%description  hva-common-vmapp-config
<insert long description, indented with spaces>

# hypervisor:kvm
%package hva-kvm-vmapp-config
Summary: Configuration set for hva KVM VM appliance
Group: Development/Languages
Requires: %{name}-hva-common-vmapp-config = %{version}-%{release}
%ifarch x86_64
Requires: qemu-kvm
%endif
%description  hva-kvm-vmapp-config
<insert long description, indented with spaces>

# hypervisor:lxc
%package hva-lxc-vmapp-config
Summary: Configuration set for hva LXC VM appliance
Group: Development/Languages
Requires: %{name}-hva-common-vmapp-config = %{version}-%{release}
Requires: lxc
%description  hva-lxc-vmapp-config
<insert long description, indented with spaces>

# hypervisor:openvz
%package hva-openvz-vmapp-config
Summary: Configuration set for hva OpenVZ VM appliance
Group: Development/Languages
Requires: %{name}-hva-common-vmapp-config = %{version}-%{release}
Requires: vzkernel
Requires: vzctl
Requires: kmod-openvswitch-vzkernel
%description  hva-openvz-vmapp-config
<insert long description, indented with spaces>

# hypervisor:*
%package hva-full-vmapp-config
Summary: Configuration set for hva OpenVZ VM appliance
Group: Development/Languages
Requires: %{name}-hva-common-vmapp-config = %{version}-%{release}
Requires: %{name}-hva-kvm-vmapp-config = %{version}-%{release}
Requires: %{name}-hva-lxc-vmapp-config = %{version}-%{release}
Requires: %{name}-hva-openvz-vmapp-config = %{version}-%{release}
# build openvswitch module for vzkernel
#Requires: kernel-devel
#Requires: vzkernel-devel
#Requires: dkms
%description hva-full-vmapp-config
<insert long description, indented with spaces>

## rpmbuild -bp
%prep
[ -d %{name}-%{version} ] || git clone %{_vdc_git_uri} %{name}-%{version}
cd %{name}-%{version}
git pull
%setup -T -D

## rpmbuild -bc
%build
RUBYDIR=%{prefix}/%{name}/ruby rpmbuild/rules build

## rpmbuid -bi
%install
# don't run "rpmbuild/rules binary"
CURDIR=${RPM_BUILD_ROOT} rpmbuild/rules binary-arch

[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}

# directory list via debian/dirs
sed "s,usr/share/axsh,%{_prefix_path},g" ./debian/dirs | while read dir; do
  [ -d ${RPM_BUILD_ROOT}/${dir} ] || mkdir -p ${RPM_BUILD_ROOT}/${dir}
done

components="
 dcmgr
 frontend
 rpmbuild
"
for component in ${components}; do
  rsync -aHA --exclude=".git/*" --exclude="*~" `pwd`/${component} ${RPM_BUILD_ROOT}/%{prefix}/%{name}/
done
unset components

rsync -aHA %{prefix}/%{name}/ruby ${RPM_BUILD_ROOT}/%{prefix}/%{name}/

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

[ -d ${RPM_BUILD_ROOT}/etc/%{name} ] || mkdir -p ${RPM_BUILD_ROOT}/etc/%{name}
[ -d ${RPM_BUILD_ROOT}/etc/%{name}/dcmgr_gui ] || mkdir -p ${RPM_BUILD_ROOT}/etc/%{name}/dcmgr_gui

# rails app config
[ -f ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/database.yml ] && rm -f ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/database.yml
ln -s /etc/%{name}/dcmgr_gui/database.yml      ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/database.yml
ln -s /etc/%{name}/dcmgr_gui/instance_spec.yml ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/instance_spec.yml
ln -s /etc/%{name}/dcmgr_gui/dcmgr_gui.yml     ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/config/dcmgr_gui.yml

# log directory
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{name}
mkdir -p ${RPM_BUILD_ROOT}/var/log/%{name}/dcmgr_gui
ln -s /var/log/%{name}/dcmgr_gui ${RPM_BUILD_ROOT}/%{prefix}/%{name}/frontend/dcmgr_gui/log

# lib directory
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{name}
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{name}/tmp
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{name}/tmp/instances
mkdir -p ${RPM_BUILD_ROOT}/var/lib/%{name}/tmp/images

%clean
RUBYDIR=%{prefix}/%{name}/ruby rpmbuild/rules clean
rm -rf %{prefix}/%{name}/ruby
rm -rf ${RPM_BUILD_ROOT}

%post
/sbin/chkconfig       ntpd on
/sbin/chkconfig       ntpdate on
/sbin/chkconfig --add vdc-net-event

%post debug-config
%{prefix}/%{name}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-dump-core.conf

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
%{prefix}/%{name}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-bridge-if.conf
%{prefix}/%{name}/rpmbuild/helpers/add-loopdev.sh
%{prefix}/%{name}/rpmbuild/helpers/set-openvswitch-conf.sh

%post hva-openvz-vmapp-config
%{prefix}/%{name}/rpmbuild/helpers/sysctl.sh < /etc/sysctl.d/30-openvz.conf

%files
%defattr(-,root,root)
%{prefix}/%{name}/
%config /etc/logrotate.d/flog-vdc
%config /etc/init.d/vdc-net-event
%config(noreplace) /etc/default/wakame-vdc
%config /etc/prelink.conf.d/wakame-vdc.conf
%dir /etc/%{name}/
%dir /var/log/%{name}
%dir /var/lib/%{name}
%dir /var/lib/%{name}/tmp

%files debug-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-dump-core.conf

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
%dir /etc/%{name}/dcmgr_gui
%dir /var/log/%{name}/dcmgr_gui
%dir /var/lib/%{name}/tmp/images

%files hva-common-vmapp-config
%defattr(-,root,root)
%config(noreplace) /etc/default/vdc-hva
%config /etc/init/vdc-hva.conf
%config /etc/sysctl.d/30-bridge-if.conf
%dir /var/lib/%{name}/tmp/instances

%files hva-kvm-vmapp-config

%files hva-lxc-vmapp-config

%files hva-openvz-vmapp-config
%defattr(-,root,root)
%config /etc/sysctl.d/30-openvz.conf

%files hva-full-vmapp-config

%changelog
