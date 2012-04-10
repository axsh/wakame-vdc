#!/bin/sh
# リモート(dcmgr)のmd5sumをパスワード入力なしで実行できること（sshの公開鍵認証など）
export REMOTE_BASE="$1"
shift
export MD5_CMD=md5sum
export SSH_USER=root
export DCMGR_HOST=${SSH_USER}@`hostname`
export SSH_CMD="cd ${REMOTE_BASE};${MD5_CMD} $*"
ssh ${DCMGR_HOST} "${SSH_CMD}"
