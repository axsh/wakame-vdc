#!/bin/sh
#
# $ inst-ls.sh
# $ inst-ls.sh -l
#
LANG=C
LC_ALL=C

switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
ipaddr=$(/sbin/ip addr show ${switch} | grep -w inet | awk '{print $2}')
myaddr=${ipaddr%%/*}
tmpfile=/tmp/_$(basename $0).$(date +%Y%m%d-%s).$$
width=5


kvm_ps() {
  ps -e -o command | egrep -w '[k]vm' | egrep -v "sed|$0" | sed 's,^ *kvm,kvm,' | while read line; do
    set ${line}

    instance_id=
    vnc_port=

    prev_type=val
    prev_val=
    while [ $# -gt 0 ]; do
      case $1 in
      kvm)
        echo "  $1"
        prev_type=val
        prev_val=$1
        ;;
      -*)
        [ ${prev_type} = "opt" ] && printf " %${width}s\n" ${prev_val}
        prev_type=opt
        prev_val=${1}
        ;;
      *)
        [ ${prev_type} = "opt" ] && printf " %${width}s %s\n" ${prev_val} $1
        case ${prev_val} in
        -name) instance_id=${1##vdc-};;
        -vnc)  vnc_port=$((${1##:} + 5900));;
        *) ;;
        esac
        prev_type=val
        prev_val=$1
        ;;
      esac
      shift
    done > ${tmpfile}

    echo "[ ${instance_id} ] vnc: ${myaddr}:${vnc_port}"
    cat ${tmpfile}
    echo
  done

  [ -f ${tmpfile} ] && rm -f ${tmpfile}
}

lxc_ps() {
  ps -e -o command | egrep -w '[l]xc-start' | while read line; do
    set ${line}

    instance_id=
    instance_dir=

    prev_type=val
    prev_val=
    while [ $# -gt 0 ]; do
      case $1 in
      lxc-start)
        echo "  $1"
        prev_type=val
        prev_val=$1
        ;;
      -*)
        [ ${prev_type} = "opt" ] && printf " %${width}s\n" ${prev_val}
        prev_type=opt
        prev_val=$1
        ;; 
      *)
        [ ${prev_type} = "opt" ] && printf " %${width}s %s\n" ${prev_val} $1
        case ${prev_val} in
        -n)
          instance_id=$1
          ;;
        -o)
          instance_dir=$(dirname $1)
          ;;
        *)
          ;;
        esac
        prev_type=val
        prev_val=$1
        ;; 
      esac
      shift
    done > ${tmpfile}

    echo "[ ${instance_id} ]"
    cat ${tmpfile}
    echo

#    for conf in ${instance_dir}/config.${instance_id}; do
#      echo "  -> ${conf}"
#      [ -f ${conf} ] && sed 's,^,     ,' ${conf}
#      echo
#    done

    echo
    {
    echo "\$ ls -la ${instance_dir}"
    ls -la ${instance_dir}
    } | sed "s,^,    ,"
    echo
  done

  [ -f ${tmpfile} ] && rm -f ${tmpfile}
}

case $1 in
-l*)
  ps -e | egrep -w '[k]vm'       -q && kvm_ps
  ps -e | egrep -w '[l]xc-start' -q && lxc_ps
  ;;
*)
  {
  ps -ef | egrep -w '[k]vm'
  ps -ef | egrep -w '[l]xc-start'
  } | while read line; do
    set ${line}
    echo ${line}
    echo
    pstree -pal $2
  done
  ;;
esac

exit 0
