#!/bin/sh
#
# $ nsa-ps.sh
#

LANG=C
LC_ALL=C

ps -ef | egrep '[b]in/nsa' | while read line; do
  set ${line}
  echo $*
  echo
  pstree -pal $2
done
