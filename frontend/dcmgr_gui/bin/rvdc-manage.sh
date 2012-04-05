#!/bin/sh
# リモート(dcmgr)のvdc-manageをパスワード入力なしで実行できること（sshの公開鍵認証など）
export REMOTE_BASE=/usr/share/axsh/wakame-vdc/dcmgr
export VDC_CMD=./bin/vdc-manage
export SSH_USER=root
export DCMGR_HOST=${SSH_USER}@`hostname`
export SSH_CMD="export GEM_HOME=${REMOTE_BASE}/.vender/bundle/ruby/1.8;BUNDLE_GEMFILE=${REMOTE_BASE}/Gemfile;cd ${REMOTE_BASE};${VDC_CMD} $*"
cur_path=`pwd`
my_path=`dirname $0` 
printf "%s REMOTE COMMAND[%s]\n" "`date +'%D %T'`" "ssh ${DCMGR_HOST} ${SSH_CMD}" >> ${cur_path}/${my_path}/../log/rvdc_manage.log 
ssh ${DCMGR_HOST} "${SSH_CMD}"
