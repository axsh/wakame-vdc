%define tmp_file "/tmp/rpm.kmod-kpkg.%(whoami).tmp"

# * rpmbuild -ba kmod-openvswitch-_VER_.spec \
# --define 'kpkg   kernel'
# --define 'kver   2.6.32-220'
# --define 'ovsver 1.4.1'

%define _buildshell /bin/bash

%define kpkg_name kernel
%{?kpkg:%define kpkg_name %{kpkg}}

%define kpkg_devel_name %{kpkg_name}-devel
%global latest_kernel_variant %(rpm --qf '%{Version}-%{Release}\\n' -qa ^%{kpkg_devel_name} | sort -r | head -1)
# select the latest version.
%{!?kver: %global kernel_variant %(rpm --qf '%{Version}-%{Release}\\n' -qa ^%{kpkg_devel_name} | sort -r | head -1)}
%{?kver: %global kernel_variant %{kver}}

%define test_kernel_pkg %(rpm -ql %{kpkg_devel_name}-%{kernel_variant} >/dev/null; echo $?)
# if undefined...
%{!?test_kernel_pkg: %global kernel_variant %(rpm --qf '%{Version}-%{Release}\\n' -qa ^%{kpkg_devel_name} | sort -r | head -1)}

# encode - to _ to be able to include that in a package name or release "number"
%define krelver %(echo %{kernel_variant} | tr -s '-' '_')

%define kernel_source_dir %(rpm -ql %{kpkg_devel_name}-%{kernel_variant} | egrep /usr/src/kernels/${kernel_variant} > %{tmp_file} && head -1 %{tmp_file})
%define kernel_lib_dir %(rpm -ql %{kpkg_name}-%{kernel_variant} | grep /lib/modules/ > %{tmp_file} && head -1 %{tmp_file})
%define kernel_lib_version %(basename %{kernel_lib_dir})

%define kernelversion %{kernel_lib_version}

%define oname openvswitch
%define oname_base_uri http://openvswitch.org/releases
%define oname_version 1.4.2
%{?ovsver:%define oname_version %{ovsver}}

Name: kmod-%{oname}
Version: %{oname_version}
Release: 1%{?dist}
Summary: Open vSwitch kernel module
Group: System/Kernel
License: GPLv2
URL: http://openvswitch.org/
Source:  %{oname_base_uri}/%{oname}-%{version}.tar.gz
BuildRequires: %{kpkg_devel_name} = %{kernel_variant}
Requires: %{kpkg_name} = %{kernel_variant}
Requires: %{oname} = %{version}-%{release}
Requires: module-init-tools

%description
Open vSwitch Linux kernel module.

%package %{krelver}
Summary: Open vSwitch kernel module
Group: System/Kernel

%description %{krelver}
Open vSwitch Linux kernel module.

%prep
echo test_kernel_pkg:%{test_kernel_pkg}
[ "%{test_kernel_pkg}" -ne 0 ] && {
  echo "[ERROR] no such kernel: %{kpkg_name}-%{kernel_variant}" >&2
  exit 1
}

[ -f ${RPM_SOURCE_DIR}/%{oname}-%{version}.tar.gz ] || {
  curl -o ${RPM_SOURCE_DIR}/%{oname}-%{version}.tar.gz -O %{oname_base_uri}/%{oname}-%{version}.tar.gz
}
[ -d %{name}-%{version} ] || {
  tar zxvf ${RPM_SOURCE_DIR}/%{oname}-%{version}.tar.gz -C ${RPM_BUILD_DIR}/
  mv %{oname}-%{version} %{name}-%{version}
}
%setup -T -D

%build
./configure --with-linux='/lib/modules/%{kernelversion}/build'
make -C datapath/linux

%install
[ -d ${RPM_BUILD_ROOT}/lib/modules/%{kernelversion}/extra/%{oname} ] || mkdir -p ${RPM_BUILD_ROOT}/lib/modules/%{kernelversion}/extra/%{oname}
rsync -aHA `pwd`/datapath/linux/*.ko ${RPM_BUILD_ROOT}/lib/modules/%{kernelversion}/extra/%{oname}/

%clean
rm -rf ${RPM_BUILD_ROOT}

#           install    upgrade  uninstall
# %pre      $1 == 1   $1 == 2   (N/A)
# %post     $1 == 1   $1 == 2   (N/A)
# %preun    (N/A)     $1 == 1   $1 == 0
# %postun   (N/A)     $1 == 1   $1 == 0

%post
echo "Adding any weak-modules"
cat <<EOS | /sbin/weak-modules --add-modules
/lib/modules/%{kernelversion}/extra/%{oname}/brcompat_mod.ko
/lib/modules/%{kernelversion}/extra/%{oname}/openvswitch_mod.ko
EOS

%prerun
if [ "$1" = "0" ]; then     # $1 = 0 for uninstall
  echo "Removing any linked weak-modules"
  cat <<EOS | /sbin/weak-modules --remove-modules
/lib/modules/%{kernelversion}/extra/%{oname}/brcompat_mod.ko
/lib/modules/%{kernelversion}/extra/%{oname}/openvswitch_mod.ko
EOS
fi

%files %{krelver}
%defattr(-,root,root)
/lib/modules/%{kernelversion}/extra/%{oname}/brcompat_mod.ko
/lib/modules/%{kernelversion}/extra/%{oname}/openvswitch_mod.ko

%changelog
