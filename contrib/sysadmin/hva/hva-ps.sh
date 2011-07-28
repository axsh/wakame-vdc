#1/bn/sh

LANG=C
LC_ALL=C

ps -ef | egrep '[b]in/hva' | while read line; do
  set ${line}
  echo ${line}
  echo
  pstree -pal $2
done
