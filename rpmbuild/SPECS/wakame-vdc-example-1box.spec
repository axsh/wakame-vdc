%define _prefix_path opt/axsh
%define _vdc_git_uri git://github.com/axsh/wakame-vdc.git
%define oname wakame-vdc
%define osubname example-1box

# * rpmbuild -bb ./wakame-vdc-example-1box.spec \
# --define "version_tag [ tag ]"
# --define "build_id $(../helpers/gen-release-id.sh)"
# --define "build_id $(../helpers/gen-release-id.sh [ commit-hash ])"
# --define "repo_uri git://github.com/axsh/wakame-vdc.git"

%define version_id 15.03
%define release_id 1.daily
%{?version_tag:%define version_id %{version_tag}}
%{?build_id:%define release_id %{build_id}}
%{?repo_uri:%define _vdc_git_uri %{repo_uri}}

Name: %{oname}-%{osubname}
Version: %{version_id}
Release: %{release_id}%{?dist}
Summary: The wakame virtual data center.
Group: Development/Languages
Vendor: Axsh Co. LTD <dev@axsh.net>
URL: http://wakame.jp/
Source: %{_vdc_git_uri}
Prefix: /%{_prefix_path}
License: see https://github.com/axsh/wakame-vdc/blob/master/README.md
BuildArch: noarch

%description
<insert long description, indented with spaces>

# example:common
%package common-vmapp-config
Summary: Configuration set for common %{osubname}
Group: Development/Languages
Requires: %{oname}-vdcsh
%description common-vmapp-config
<insert long description, indented with spaces>

# example:dcmgr
%package dcmgr-vmapp-config
Summary: Configuration set for dcmgr %{osubname}
Group: Development/Languages
Requires: %{oname}-dcmgr-vmapp-config
Requires: %{name}-common-vmapp-config
%description dcmgr-vmapp-config
<insert long description, indented with spaces>

# example:webui
%package webui-vmapp-config
Summary: Configuration set for webui %{osubname}
Group: Development/Languages
Requires: %{oname}-webui-vmapp-config
Requires: %{name}-common-vmapp-config
%description webui-vmapp-config
<insert long description, indented with spaces>

# example:proxy
%package proxy-vmapp-config
Summary: Configuration set for proxy %{osubname}
Group: Development/Languages
Requires: %{oname}-proxy-vmapp-config
Requires: %{name}-common-vmapp-config
%description proxy-vmapp-config
<insert long description, indented with spaces>

# example:admin
%package admin-vmapp-config
Summary: Configuration set for admin %{osubname}
Group: Development/Languages
Requires: %{oname}-admin-vmapp-config
Requires: %{name}-common-vmapp-config
%description admin-vmapp-config
<insert long description, indented with spaces>

# example:hva
%package hva-vmapp-config
Summary: Configuration set for hva %{osubname}
Group: Development/Languages
Requires: %{oname}-hva-full-vmapp-config
Requires: %{name}-common-vmapp-config
%description hva-vmapp-config
<insert long description, indented with spaces>

# example:nsa
%package nsa-vmapp-config
Summary: Configuration set for nsa %{osubname}
Group: Development/Languages
Requires: %{oname}-nsa-vmapp-config
Requires: %{name}-common-vmapp-config
%description nsa-vmapp-config
<insert long description, indented with spaces>

# example:sta
%package sta-vmapp-config
Summary: Configuration set for sta %{osubname}
Group: Development/Languages
Requires: %{oname}-sta-vmapp-config
Requires: %{name}-common-vmapp-config
%description sta-vmapp-config
<insert long description, indented with spaces>

# example:full
%package full-vmapp-config
Summary: Configuration set for full %{osubname}
Group: Development/Languages
Requires: %{name}-dcmgr-vmapp-config
Requires: %{name}-proxy-vmapp-config
Requires: %{name}-webui-vmapp-config
Requires: %{name}-nsa-vmapp-config
Requires: %{name}-sta-vmapp-config
Requires: %{name}-hva-vmapp-config
Requires: %{name}-admin-vmapp-config
%description full-vmapp-config
<insert long description, indented with spaces>

# example:experiment
%package experiment-vmapp-config
Summary: Configuration set for experiment %{osubname}
Group: Development/Languages
Requires: %{name}-full-vmapp-config
%description experiment-vmapp-config
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

## rpmbuid -bi
%install
[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}

mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}
mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs
mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui
mkdir -p ${RPM_BUILD_ROOT}/etc/%{oname}/admin

# generate /etc/%{oname}/*.conf
config_examples="dcmgr nsa sta"
for config_example in ${config_examples}; do
  cp -p `pwd`/dcmgr/config/${config_example}.conf.example ${RPM_BUILD_ROOT}/etc/%{oname}/${config_example}.conf
done
unset config_examples
cp -p `pwd`/dcmgr/config/convert_specs/load_balancer.yml.example ${RPM_BUILD_ROOT}/etc/%{oname}/convert_specs/load_balancer.yml

VDC_ROOT=/var/lib/%{oname}
config_templates="proxy hva"
for config_template in ${config_templates}; do
  echo "$(eval "echo \"$(cat `pwd`/tests/vdc.sh.d/${config_template}.conf.tmpl)\"")" > ${RPM_BUILD_ROOT}/etc/%{oname}/${config_template}.conf
done
unset config_templates
unset VDC_ROOT

# /etc/%{oname}/dcmgr_gui/*.yml
config_ymls="database instance_spec dcmgr_gui load_balancer_spec"
for config_yml in ${config_ymls}; do
  cp -p `pwd`/frontend/dcmgr_gui/config/${config_yml}.yml.example ${RPM_BUILD_ROOT}/etc/%{oname}/dcmgr_gui/${config_yml}.yml
done
unset config_ymls

# /etc/%{oname}/admin/*.yml
config_ymls="admin"
for config_yml in ${config_ymls}; do
  cp -p `pwd`/frontend/admin/config/${config_yml}.yml.example ${RPM_BUILD_ROOT}/etc/%{oname}/admin/${config_yml}.yml
done
unset config_ymls

%post common-vmapp-config
/sbin/chkconfig       ntpd on
/sbin/chkconfig       ntpdate on

%post dcmgr-vmapp-config
/sbin/chkconfig --add mysqld
/sbin/chkconfig       mysqld on
/sbin/chkconfig --add rabbitmq-server
/sbin/chkconfig       rabbitmq-server on
# activate upstart system job
sys_default_confs="auth collector dcmgr metadata nsa proxy sta webui"
for sys_default_conf in ${sys_default_confs}; do
  sed -i s,^#RUN=.*,RUN=yes, /etc/default/vdc-${sys_default_conf}
done

# set demo parameters
for sys_default_conf in /etc/default/vdc-*; do sed -i s,^#NODE_ID=.*,NODE_ID=demo1, ${sys_default_conf}; done
[ -f /etc/wakame-vdc/unicorn-common.conf ] && sed -i "s,^worker_processes .*,worker_processes 1," /etc/wakame-vdc/unicorn-common.conf

%post hva-vmapp-config
/sbin/chkconfig --add iscsi
/sbin/chkconfig       iscsi  on
/sbin/chkconfig --add iscsid
/sbin/chkconfig       iscsid on
/sbin/chkconfig --add tgtd
/sbin/chkconfig       tgtd on
# activate upstart system job
sys_default_confs="hva"
for sys_default_conf in ${sys_default_confs}; do
  sed -i s,^#RUN=.*,RUN=yes, /etc/default/vdc-${sys_default_conf}
done

%post experiment-vmapp-config
# add ifcfg-br0 ifcfg-eth0
%{prefix}/%{oname}/rpmbuild/helpers/setup-bridge-if.sh
# add vzkernel entry
%{prefix}/%{oname}/rpmbuild/helpers/edit-grub4vz.sh add
# edit boot order to use vzkernel as default.
%{prefix}/%{oname}/rpmbuild/helpers/edit-grub4vz.sh enable

# set demo parameters
for sys_default_conf in /etc/default/vdc-*; do sed -i s,^#NODE_ID=.*,NODE_ID=demo1, ${sys_default_conf}; done

%clean
rm -rf ${RPM_BUILD_ROOT}

%files common-vmapp-config
%defattr(-,root,root)

%files dcmgr-vmapp-config
%config(noreplace) /etc/%{oname}/dcmgr.conf
%config(noreplace) /etc/%{oname}/convert_specs/load_balancer.yml

%files proxy-vmapp-config
%config(noreplace) /etc/%{oname}/proxy.conf

%files webui-vmapp-config
%config(noreplace) /etc/%{oname}/dcmgr_gui/database.yml
%config(noreplace) /etc/%{oname}/dcmgr_gui/instance_spec.yml
%config(noreplace) /etc/%{oname}/dcmgr_gui/dcmgr_gui.yml
%config(noreplace) /etc/%{oname}/dcmgr_gui/load_balancer_spec.yml

%files admin-vmapp-config
%config(noreplace) /etc/%{oname}/admin/admin.yml

%files hva-vmapp-config
%config(noreplace) /etc/%{oname}/hva.conf

%files nsa-vmapp-config
%config(noreplace) /etc/%{oname}/nsa.conf

%files sta-vmapp-config
%config(noreplace) /etc/%{oname}/sta.conf

%files full-vmapp-config

%files experiment-vmapp-config

%changelog
