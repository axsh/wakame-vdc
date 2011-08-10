#!/bin/sh

LANG=C
LC_ALL=C


cmd=${1:-comstar}
subcmd=${2:-}

case ${cmd} in
switch)
  case ${subcmd} in
  comstar)
    pfexec svcadm disable iscsitgt
    pfexec svcadm enable svc:/network/iscsi/target:default
    pfexec svcadm enable stmf
    echo "=> $ pfexec reboot"
    ;;
  sun_iscsi)
    pfexec svcadm enable iscsitgt
    pfexec svcadm disable svc:/network/iscsi/target:default
    pfexec svcadm disable stmf
    echo "=> $ pfexec reboot"
    ;;
  *)
    echo "$ $0 ${cmd} [ comstar | sun_iscsi ]" >&2
    exit 1
    ;;
  esac
  ;;
status)
  svcs | grep iscsi
  ;;
*)
  echo "$ $0 [switch | status] [sub commands...]" >&2
  exit 1
esac


