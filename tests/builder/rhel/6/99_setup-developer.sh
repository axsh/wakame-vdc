#!/bin/bash

set -e

work_dir=${work_dir:?"work_dir needs to be set"}
builder_path=${builder_path:?"builder_path needs to be set"}


#
# MySQL
#
#dcmgr_dbname=wakame_dcmgr
#dcmgr_dbuser=root
#webui_dbname=wakame_dcmgr_gui
#webui_dbpass=passwd

echo "# Configure Database for MySQL ..."
echo | mysql -uroot ${dcmgr_dbname} && yes | mysqladmin -uroot drop ${dcmgr_dbname} >/dev/null 2>&1
echo | mysql -uroot ${webui_dbname} && yes | mysqladmin -uroot drop ${webui_dbname} >/dev/null 2>&1

cat <<EOS | mysql -uroot
create database ${dcmgr_dbname} default character set utf8;
create database ${webui_dbname} default character set utf8;
grant all on ${webui_dbname}.* to ${webui_dbname}@localhost identified by '${webui_dbpass:-passwd}'
EOS


#
# packages
#

# rpm packages
rpm_pkgs="
 git
 screen
 tmux
"

# rake was deleted

#
# install
#
yum install -y ${rpm_pkgs}

[ -d ${work_dir} ] || mkdir ${work_dir}
cd ${work_dir}

function bundle_update() {
  local dir=$1

  [ -d $dir ] || exit 1
  # run in subshell to keep cwd.
  (
  cd $dir

  [ -d .vendor/bundle ] && rm -rf .vendor/bundle
  # this oneliner will generate .bundle/config.
  shlog bundle install --path=.vendor/bundle
  )
}

echo "before bundle_update"

bundle_update ${work_dir}/dcmgr/
bundle_update ${work_dir}/frontend/dcmgr_gui/


# prepare configuration files

# dcmgr
cd ${work_dir}/dcmgr/config/
cp -f dcmgr.conf.example dcmgr.conf
cp -f snapshot_repository.yml.example snapshot_repository.yml
cp -f hva.conf.example hva.conf
cp -f nsa.conf.example nsa.conf
cp -f sta.conf.example sta.conf

# dcmgr:hva
[ -d ${vmdir_path} ] || mkdir $vmdir_path
perl -pi -e "s,^config.vm_data_dir = .*,config.vm_data_dir = \"${vmdir_path}\"," hva.conf

# frontend
cd ${work_dir}/frontend/dcmgr_gui/config/
cp -f dcmgr_gui.yml.example dcmgr_gui.yml

# deploy 91_generate-demo-resource.sh
cp -f ${builder_path}/ubuntu/10.04/91_generate-demo-resource.sh ${builder_path}/$DISTRIB_ID/$DISTRIB_RELEASE/


exit 0
