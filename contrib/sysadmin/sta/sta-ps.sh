#!/bin/sh
#
# $ nsa-ps.sh
#

LANG=C
LC_ALL=C

ps -ef | egrep '[b]in/sta' | while read line; do
  set ${line}
  echo $*
  echo
  which pstree >/dev/null 2>&1 && pstree -pal $2
done
