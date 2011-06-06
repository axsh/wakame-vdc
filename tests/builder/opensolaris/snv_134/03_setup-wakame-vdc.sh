#!/bin/sh

export LANG=C
export LC_ALL=C
export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin:/bin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT


# wakame-vdc installation
echo "#Setting up wakame-vdc ..."
{
cat <<'EOS'
whoami
wakame_vdc_version=10.11.0

gem_pkgs="
 wakame-vdc-agents=${wakame_vdc_version}
"
# i18n=0.4.2
# mail=2.2.10
# wakame-vdc-dcmgr=${wakame_vdc_version}
# wakame-vdc-webui=${wakame_vdc_version}

for gem_pkg in ${gem_pkgs}; do
  gempkg_name=${gem_pkg%%=*}
  gempkg_ver=${gem_pkg##*=}

  gem list | grep -w ${gempkg_name} >/dev/null || {
    gem install ${gempkg_name} --no-rdoc --no-ri -v ${gempkg_ver}
  }
done
EOS
} | su - wakame -c /usr/bin/bash


# wakame system configuration
[ -d /export/home/wakame/vdc ] || {
  su - wakame -c "mkdir /export/home/wakame/vdc"
}

[ -d /export/home/wakame/vdc/sta/snaps ] || {
  su - wakame -c "mkdir -p /export/home/wakame/vdc/sta/snap"
}

exit 0
