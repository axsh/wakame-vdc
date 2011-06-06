#!/bin/sh

home_dir=/export/home/wakame/
work_dir=${home_dir}/work

gem_pkgs="
 bundler
 rake
"

for gem_pkg in ${gem_pkgs}; do
  gem list | egrep -q -w ${gem_pkg} || {
    gem install ${gem_pkg} --no-ri --no-rdoc
  }
done

[ -d ${work_dir} ] || mkdir ${work_dir}
cd ${work_dir}

[ -d wakame-vdc  ] || git clone git://github.com/axsh/wakame-vdc.git


cd ${work_dir}/wakame-vdc
bundle_update() {

  dir=$1

  [ -d $dir ] || exit 1
  cd $dir

  [ -d .bundle ] || mkdir .bundle
  cat <<EOS > .bundle/config
BUNDLE_DISABLE_SHARED_GEMS: "1"
BUNDLE_WITHOUT: ""
BUNDLE_PATH: vendor/bundle
EOS

  bundle update
}

cd ${work_dir}/wakame-vdc/dcmgr/
perl -pi -e 's, gem "mysql", #gem "mysql",' Gemfile
perl -pi -e 's, gem "unicorn", #gem "unicorn",' Gemfile

bundle_update ${work_dir}/wakame-vdc/dcmgr/


cat <<EOS > ${home_dir}/.screenrc
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<"
defscrollback 10000
EOS

#cd ${work_dir}/wakame-vdc/dcmgr/config/


