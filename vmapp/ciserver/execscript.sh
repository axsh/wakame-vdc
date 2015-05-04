#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main
configure_hypervisor ${chroot_dir}

### wakame-init

install_wakame_init ${chroot_dir} ${VDC_METADATA_TYPE} ${VDC_DISTRO_NAME}

## custom build procedure

chroot $1 $SHELL -ex <<'EOS'
  # pre-setup
  yum install -y --disablerepo=updates git

  # installation
  addpkgs="
   hold-releasever.hold-baseurl
   jenkins.master
   hubot.common
   jenkins.plugin.rbenv
   httpd
   rpmbuild
  "

  if [[ -z "$(echo ${addpkgs})" ]]; then
    exit 0
  fi

  deploy_to=/var/tmp/buildbook-rhel6

  if ! [[ -d "${deploy_to}" ]]; then
    git clone https://github.com/wakameci/buildbook-rhel6.git ${deploy_to}
  fi

  cd ${deploy_to}
  git checkout master
  git pull

  ./run-book.sh ${addpkgs}

  # service configuration
  svcs="
   jenkins
   httpd
  "
  for svc in ${svcs}; do
    chkconfig --list ${svc}
    chkconfig ${svc} on
    chkconfig --list ${svc}
  done

  # cleanup
  history -c
EOS

## user-data script

chroot $1 $SHELL -ex <<'EOS'
  echo '[ -f /metadata/user-data ] && . /metadata/user-data' >> /etc/rc.d/rc.local
EOS

##

user=wakame-vdc

chroot $1 $SHELL -ex <<EOS
su - ${user} <<'_EOS_'
  set -e
  set -o pipefail
  set -x
  mkdir myhubot
  cd    myhubot
  yo hubot \
   --adapter=hipchat \
   --name=hubot \
   --owner=hubot \
   --description=hubot \
   <<< "Y"
  history -c
_EOS_
EOS

##

cat <<'_EOS_' > $1/etc/init/hubot.conf
description Hubot

respawn
respawn limit 5 60

chdir /home/wakame-vdc/myhubot

script
  sleep 3
  su - wakame-vdc -c /bin/bash <<EOS >>/var/log/hubot.log 2>&1
    [ -f /etc/default/hubot.conf ] && . /etc/default/hubot.conf
    export HUBOT_JENKINS_URL="${HUBOT_JENKINS_URL:-"http://127.0.0.1:8080/"}"
    cd /home/wakame-vdc/myhubot
    ./bin/hubot -a hipchat
EOS
end script
_EOS_

cat <<'_EOS_' > $1/etc/default/hubot.conf
#export HUBOT_HIPCHAT_JID="********@chat.hipchat.com"
#export HUBOT_HIPCHAT_PASSWORD="********"
#export HUBOT_LOG_LEVEL="debug"
#export HUBOT_JENKINS_URL="http://127.0.0.1:8080/"
_EOS_
