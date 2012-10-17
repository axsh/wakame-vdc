#!/bin/bash
# Emulation of cgexec from libcg using bash.

set -e

[[ "$UID" -ne 0 ]] && { echo "ERROR: Run in root user." >&2; exit 1;}

declare -a nslist

while getopts "g:c:" flag; do
  case $flag in
    \?) OPT_ERROR=1; break;;
    g) nslist[${#nslist[@]}]="$OPTARG";;
    c) cmdline="$OPTARG";;
  esac
done

shift `expr $OPTIND - 1`

for i in ${nslist[@]}
do
  subsystem=$(echo "${i}" | cut -d: -f1)
  cgns=$(echo "${i}" | cut -d: -f2)
  cgns="/${cgns}"

  cgbase=$(findmnt -n -t cgroup -O "$subsystem" | awk '{print $1}')
  [[ -z "$cgbase" ]] && { echo "Unknown cgroup subsystem: ${subsystem}" >&2; exit 1; }
  echo "$$" >> "${cgbase}${cgns}/tasks"
done

if [[ -n "$cmdline" ]]; then
  exec /bin/bash -c "$cmdline"
else
  exec $*
fi
