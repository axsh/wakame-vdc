#!/bin/bash
#
#
set -e

LANG=C
LC_ALL=C

#abs_path=$(cd $(dirname $0) && pwd)
#cd ${abs_path}
specfile=${1:-../SPECS/wakame-vdc.spec}

[ -f ${specfile} ] || {
  echo "no such file: ${specfile}" >&2
  exit 1
}

deplist_via_specfile () {
  rpm -qR --specfile -f ${specfile} \
   | sort \
   | uniq
}

path2name () {
  cat | while read line; do
     case ${line} in
     /*)
       rpm -qf ${line} --qf '%{NAME}\n'
       ;;
     *)
       echo ${line}
       ;;
     esac
   done \
   | sort \
   | uniq
}

report() {
  cat | while read name; do
    rpm -qi ${name} >/dev/null && {
      rpm -q --qf '%{INSTALLTIME} %{NAME} %{Version} %{Release} %{ARCH}\n' ${name}
    } || {
      echo "xxxxxxxxxx ${name} xxx xxx xxx"
    }
  done
}

deplist_via_specfile \
 | grep -v wakame-vdc \
 | path2name \
 | report
