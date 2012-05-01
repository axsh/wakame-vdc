#!/bin/bash

set -e

mode=$1

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=${key##--}
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      args="${args} ${arg}"
      ;;
  esac
  shift
done

abs_path=$(cd $(dirname $0) && pwd)
vendor_dir=${vendor_dir:-${abs_path}/vendor}
[ -d ${vendor_dir} ] || mkdir -p ${vendor_dir}


function list_3rd_party() {
  cat <<EOS | egrep -v ^#
# pkg_name                         pkg_dir
epel-release-6-5.noarch.rpm        http://ftp.riken.go.jp/pub/Linux/fedora/epel/6/i386
rabbitmq-server-2.6.1-1.noarch.rpm http://www.rabbitmq.com/releases/rabbitmq-server/v2.6.1
flog-1.8-4.$(arch).rpm             http://cdimage.wakame.jp/packages/rhel/6
EOS
}

function download_3rd_party() {
  rpm -qi curl >/dev/null || yum install -y curl
  list_3rd_party | while read pkg_name pkg_dir; do
    echo downloading ${pkg_name} ...
    [ -f ${vendor_dir}/${pkg_name} ] || {
      curl ${pkg_dir}/${pkg_name} > ${vendor_dir}/${pkg_name}
    }
  done
}

function install_3rd_party() {
  list_3rd_party | while read pkg_name pkg_dir; do
    rpm -qi ${pkg_name%%.rpm} >/dev/null || yum install -y ${vendor_dir}/${pkg_name}
  done
}


case ${mode} in
download)
  download_3rd_party
  ;;
install)
  download_3rd_party
  install_3rd_party
  ;;
esac
