# -*-Shell-script-*-
#
# requires:
#   bash
#

## system variables

readonly abs_dirname=$(cd ${BASH_SOURCE[0]%/*} && pwd)
readonly shunit2_file=${abs_dirname}/../../../shunit2

## include files

. ${abs_dirname}/../../../../functions/inifile.sh

## group variables

declare inifile=${abs_dirname}/inifile.$$

## group functions

function mycnf() {
  cat <<EOS
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
EOS
}
