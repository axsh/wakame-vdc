#!/bin/bash
#
# $ pararell-curl.sh [url]
# $ thread=8 ./pararell-curl.sh [url]
#
LANG=C
LC_ALL=C

set -e

url=${url:-http://ftp.riken.jp/Linux/centos/6.0/isos/i386/CentOS-6.0-i386-bin-DVD.iso}
thread=${thread:-8}
tmp_path=${tmp_path:-/var/tmp/__$(basename $0)}
part_name=$(basename ${url})
output_dir=${output_dir:-${tmp_path}}
output_path=${output_path:-${output_dir}/${part_name}}

opts=""
# extract opts
for arg in $*; do
  case $arg in
    --*=*)
      key=${arg%%=*}; key=${key##--}
      value=${arg##--*=}
      eval ${key}=${value}
      opts="${opts} ${key}"
      ;;
  esac
done

case ${url} in
http://*|https://*)
  content_length=$(curl -s -L --head ${url} | egrep ^Content-Length | awk '{print $2}' | strings)
  ;;
file:///*)
  content_length=$(ls -l ${url##file://} | awk '{print $5}')
  ;;
*)
  [ -f ${url} ] && {
    content_length=$(ls -l ${url} | awk '{print $5}')
    url="file://${url}"
  } || {
    echo not supported scheme. >&2
    exit 1
  }
  ;;
esac

range=$((${content_length} / ${thread}))
parts=

echo content-length: ${content_length} / ${thread}

pids=
trap 'kill -9 ${pids};' 2

function shlog {
  echo "\$ $*"
  eval $*
}

[ -d ${tmp_path}   ] || mkdir -p ${tmp_path}
[ -d ${output_dir} ] || mkdir -p ${output_dir}

cur=0
while [ ${cur} -lt ${thread} ]; do
  from=$((${range} * ${cur}))
  if [ ${cur} = $((${thread} -1 )) ]; then
    to=
  else
    to=$((${range} * $((${cur} + 1)) - 1))
  fi

  part_path=${tmp_path}/${part_name}.${cur}
  shlog "curl -s -L --range ${from}-${to} -o ${part_path} ${url} &"
  pids="${pids} $!"

  parts="${parts} ${part_path}"

  cur=$((${cur} + 1))
done

echo wait: ${pids}
wait ${pids}

echo "concat parts..."
cat ${parts} > ${output_path}

for part in ${parts}; do
  [ -f ${part} ] && rm -f ${part}
done

sync

echo "=> ${output_path}"
ls -l ${output_path}
