%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git
%define oname wakame-init

# * rpmbuild -bb ./wakame-init.spec \
# --define "build_id $(../helpers/gen-release-id.sh)"
# --define "build_id $(../helpers/gen-release-id.sh [ commit-hash ])"
# --define "repo_uri git://github.com/axsh/wakame-vdc.git"

%define release_id 1.daily
%{?build_id:%define release_id %{build_id}}
%{?repo_uri:%define _vdc_git_uri %{repo_uri}}

Name: %{oname}
Version: 15.03
Release: %{release_id}%{?dist}
Summary: sysvinit script set for wakame custom image.
Group: Development/Languages
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://wakame.jp/
Source: %{_vdc_git_uri}
License: see https://github.com/axsh/wakame-vdc/blob/master/README.md
BuildArch: noarch

%description
Initialize virtual machine settings.

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

## rpmbuild -bi
%install
[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/etc/init.d/
mkdir -p ${RPM_BUILD_ROOT}/etc/default/
rsync -aHA `pwd`/wakame-init/rhel/6/wakame-init ${RPM_BUILD_ROOT}/etc/
rsync -aHA `pwd`/wakame-init/rhel/6/init.d/wakame-init ${RPM_BUILD_ROOT}/etc/init.d/
rsync -aHA `pwd`/wakame-init/rhel/6/default/wakame-init ${RPM_BUILD_ROOT}/etc/default/

%clean
rm -rf ${RPM_BUILD_ROOT}

%post 
/sbin/chkconfig --add wakame-init
/sbin/chkconfig       wakame-init on

%files
%defattr(-,root,root)
/etc/wakame-init
/etc/init.d/wakame-init
%config(noreplace) /etc/default/wakame-init

%changelog
